# 5. Backup & Restore

The application's data lives in SQLite files on the server (see
[Deploying §4.4](30-deploying.md#44-what-runs-on-the-server)). To protect against losing the
server, the primary database is **continuously replicated off-site** using
**[Litestream](https://litestream.io/)** (via the `litestream` gem). This chapter explains
what is backed up, how to confirm the backup is healthy, and how to restore after a loss.

---

## 5.1 What is backed up — and what isn't

Only the **primary** application database is replicated:

| Database | File                             | Backed up? | Why                                                              |
| -------- | -------------------------------- | ---------- | ---------------------------------------------------------------- |
| Primary  | `/data/production.sqlite3`       | **Yes**    | The real application data (members, sailings, crew, maintenance) |
| Cache    | `/data/production_cache.sqlite3` | No         | Solid Cache — regenerable working state                          |
| Queue    | `/data/production_queue.sqlite3` | No         | Solid Queue — regenerable job state                              |
| Cable    | `/data/production_cable.sqlite3` | No         | Solid Cable — regenerable WebSocket state                        |

The cache, queue, and cable databases are deliberately excluded: they hold transient state
that Rails rebuilds on its own, so there is no value in replicating them. This is set in
[`config/litestream.yml`](../../config/litestream.yml), which lists only
`/data/production.sqlite3`.

---

## 5.2 How replication works

Litestream watches the primary database's write-ahead log and streams changes to object
storage continuously — not as periodic dumps, but as a near-real-time trickle. The recovery
point is therefore typically only **seconds** of data behind live.

- **It runs inside the web server.** The Puma configuration starts Litestream as a plugin:
  `plugin :litestream if ENV["LITESTREAM_REPLICATE"]` (see [`config/puma.rb`](../../config/puma.rb)).
  There is no separate backup process or cron job to manage.
- **Only production replicates.** `LITESTREAM_REPLICATE=true` is set solely in
  [`config/deploy.prod.yml`](../../config/deploy.prod.yml). On staging and the other
  destinations the plugin stays off, so they never write to the backup.
- **Every destination can still restore.** The _replica location_ (bucket, endpoint, region)
  is defined in the base [`config/deploy.yml`](../../config/deploy.yml), so it is present on
  all destinations. Only the ability to _write_ new backups is production-only; the ability to
  _read and restore_ is available everywhere.

---

## 5.3 Where the backup lives, and its credentials

The replica is a **DigitalOcean Spaces** bucket, accessed through its S3-compatible API:

| Setting             | Value                                 | Source                                    |
| ------------------- | ------------------------------------- | ----------------------------------------- |
| Bucket              | `sailings-backup`                     | `LITESTREAM_REPLICA_BUCKET` (clear env)   |
| Path within bucket  | `production/primary`                  | `config/litestream.yml`                   |
| Endpoint            | `https://sfo3.digitaloceanspaces.com` | `LITESTREAM_REPLICA_ENDPOINT` (clear env) |
| Region              | `sfo3`                                | `LITESTREAM_REPLICA_REGION` (clear env)   |
| Access key / secret | _(encrypted)_                         | Rails credentials.yml under `litestream:` |

The non-secret settings are injected by Kamal as clear environment variables. The **Spaces
access key and secret are kept in the encrypted Rails credentials**, not in the environment,
and are wired into Litestream at boot by
[`config/initializers/litestream.rb`](../../config/initializers/litestream.rb). To view or
rotate them:

```bash
bin/rails credentials:edit
# litestream:
#   access_key_id: <spaces key>
#   secret_access_key: <spaces secret>
```

---

## 5.4 Checking the backup is healthy

The `litestream` gem exposes rake tasks. Run them inside a running container so they pick up
the credentials and replica settings — open a shell on the production destination first:

```bash
bin/kamal shell -d prod
```

Then, inside the container:

```bash
bin/rails litestream:databases                                   # list configured databases
bin/rails litestream:snapshots -- --database=/data/production.sqlite3   # list snapshots in the replica
```

`snapshots` confirms that backups are actually accumulating in Spaces; You can instead login to the DigitalOcean control panel to see the backups accumulating.

It's a good idea to restore to a temporary copy and check it. Run these occasionally — a backup you have never verified is not yet a backup you can rely on. You can do this in the container but can also do it back in your dev environment (by setting the environment variables needed). You can restore with:

```bash
LITESTREAM_REPLICA_BUCKET=sailings-backup \
LITESTREAM_REPLICA_ENDPOINT=https://sfo3.digitaloceanspaces.com \
LITESTREAM_REPLICA_REGION=sfo3 \
  bin/rails litestream:restore -- --database=/data/production.sqlite3 -o=./restored.sqlite3
```

And then run the sqlite3 client to run some SQL queries to verify the restore:

```bash
sqlite3 ./restored.sqlite3
```

---

## 5.5 Restoring

The scenario is: the server (or its data volume) is lost or corrupted, and you need to bring the database
back from Spaces. Restores can be run from **any** Kamal destination, because they all carry
the replica configuration. The below is showing how to restore to the `prod` destination, but you could also restore to staging or any other destination. REMEMBER to practice in staging first.

WARNING: Don't just copy and paste these commands verbatim! Replace the destination ('prod') with your actual destination!  Think before you paste!

### Step by step

1. **Provision and deploy the app to the target server** as normal (see
   [Deploying §4.6](30-deploying.md#46-deploying)). On first boot the entrypoint runs
   `db:prepare`, which creates an **empty** `/data/production.sqlite3`. You will replace it.

2. **From your development workstation** stop the app, and then ssh into the deployed container as the restore environment (API keys, etc) is defined there:

   ```bash
   bin/kamal app stop -d prod
   bin/kamal app exec -d prod bash -i
   ```

3. **Move the existing database files out of the way.**

```bash
   (cd /data; for f in production.sqlite3 production.sqlite3-wal production.sqlite3-shm; do
       test -e $f  && mv -v $f $f.bak
   done)
```

4. **Restore from the replica.** Litestream refuses to overwrite an existing
   database, that's why we moved the old one out of the way first:

   ```bash
   bin/rails litestream:restore -- --database=/data/production.sqlite3
   ```

   The `--database` value is the _configured_ path from `config/litestream.yml` (it is how
   Litestream finds the location of the replica).

5. **Sanity-check the restored file** before trusting it, e.g.:

```bash
    sqlite3 /data/production.sqlite3 "select count(*) from users; select count(*) from sailings;"
```

6. **Exit back to your development shell**

```bash
   exit
```

7. **Restart the production app**

```bash
   bin/kamal app boot -d prod
```

8. **Verify the running site** — sign in and check recent data, and confirm
   `https://sailings.firstsoftware.cc/up` returns healthy (see [Monitoring](50-monitoring.md)).

### After a restore

- You only restored the **primary** database. The cache, queue, and cable databases are
  recreated automatically on boot (`db:prepare`), so there is nothing to restore for them.
- Once production is confirmed healthy and replicating again, run
  `bin/rails litestream:snapshots` to confirm new backups are being written to the recovered
  database.

---

## 5.6 A note on the data volume

Litestream protects the _primary database's contents_. The host volume
`"/var/data/sailings/storage:/data"` also holds any **Active Storage** uploads (e.g. photos),
which Litestream does **not** replicate. These uploads don't matter - we have no function to upload files yet. See the volume note in [Deploying §4.4](30-deploying.md#44-what-runs-on-the-server).

---

[← Deploying](30-deploying.md) · [Manual index](README.md) · [Monitoring →](50-monitoring.md)
