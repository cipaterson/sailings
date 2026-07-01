# 4. Backup & Restore

The application's data lives in SQLite files on the server (see
[Deploying §3.4](20-deploying.md#34-what-runs-on-the-server)). To protect against losing the
server, the primary database is **continuously replicated off-site** using
**[Litestream](https://litestream.io/)** (via the `litestream` gem). This chapter explains
what is backed up, how to confirm the backup is healthy, and how to restore after a loss.

---

## 4.1 What is backed up — and what isn't

Only the **primary** application database is replicated:

| Database | File | Backed up? | Why |
|---|---|---|---|
| Primary | `/data/production.sqlite3` | **Yes** | The real application data (members, sailings, crew, maintenance) |
| Cache | `/data/production_cache.sqlite3` | No | Solid Cache — regenerable working state |
| Queue | `/data/production_queue.sqlite3` | No | Solid Queue — regenerable job state |
| Cable | `/data/production_cable.sqlite3` | No | Solid Cable — regenerable WebSocket state |

The cache, queue, and cable databases are deliberately excluded: they hold transient state
that Rails rebuilds on its own, so there is no value in replicating them. This is set in
[`config/litestream.yml`](../../config/litestream.yml), which lists only
`/data/production.sqlite3`.

---

## 4.2 How replication works

Litestream watches the primary database's write-ahead log and streams changes to object
storage continuously — not as periodic dumps, but as a near-real-time trickle. The recovery
point is therefore typically only **seconds** of data behind live.

- **It runs inside the web server.** The Puma configuration starts Litestream as a plugin:
  `plugin :litestream if ENV["LITESTREAM_REPLICATE"]` (see [`config/puma.rb`](../../config/puma.rb)).
  There is no separate backup process or cron job to manage.
- **Only production replicates.** `LITESTREAM_REPLICATE=true` is set solely in
  [`config/deploy.prod.yml`](../../config/deploy.prod.yml). On staging and the other
  destinations the plugin stays off, so they never write to the backup.
- **Every destination can still restore.** The *replica location* (bucket, endpoint, region)
  is defined in the base [`config/deploy.yml`](../../config/deploy.yml), so it is present on
  all destinations. Only the ability to *write* new backups is production-only; the ability to
  *read and restore* is available everywhere. (This is the point of the "make it easier to
  restore in other Kamal destinations" change in the git history.)

---

## 4.3 Where the backup lives, and its credentials

The replica is a **DigitalOcean Spaces** bucket, accessed through its S3-compatible API:

| Setting | Value | Source |
|---|---|---|
| Bucket | `sailings-backup` | `LITESTREAM_REPLICA_BUCKET` (clear env) |
| Path within bucket | `production/primary` | `config/litestream.yml` |
| Endpoint | `https://sfo3.digitaloceanspaces.com` | `LITESTREAM_REPLICA_ENDPOINT` (clear env) |
| Region | `sfo3` | `LITESTREAM_REPLICA_REGION` (clear env) |
| Access key / secret | *(encrypted)* | Rails credentials under `litestream:` |

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

Because the keys are decrypted with the master key, any environment that has
`config/master.key` and the replica settings (i.e. any Kamal destination) can reach the
backup.

---

## 4.4 Checking the backup is healthy

The `litestream` gem exposes rake tasks. Run them inside a running container so they pick up
the credentials and replica settings — open a shell on the production destination first:

```bash
bin/kamal shell -d prod
```

Then, inside the container:

```bash
bin/rails litestream:databases                                   # list configured databases
bin/rails litestream:snapshots -- --database=/data/production.sqlite3   # list snapshots in the replica
bin/rails litestream:verify -- --database=/data/production.sqlite3      # verify the replica is restorable
```

`snapshots` confirms that backups are actually accumulating in Spaces; `verify` restores to a
temporary copy and checks it. Run these occasionally — a backup you have never verified is not
yet a backup you can rely on.

---

## 4.5 Restoring

The scenario is: the server (or its data volume) is lost, and you need to bring the database
back from Spaces. Restores can be run from **any** Kamal destination, because they all carry
the replica configuration.

### Step by step

1. **Provision and deploy the app to the target server** as normal (see
   [Deploying §3.6](20-deploying.md#36-deploying)). On first boot the entrypoint runs
   `db:prepare`, which creates an **empty** `/data/production.sqlite3`. You will replace it.

2. **Open a shell in a container** on that destination:
   ```bash
   bin/kamal shell -d prod
   ```

3. **Restore from the replica into a fresh file.** Litestream refuses to overwrite an existing
   database, so restore to a new path:
   ```bash
   bin/rails litestream:restore -- --database=/data/production.sqlite3 -o /data/restored.sqlite3
   ```
   The `--database` value is the *configured* path from `config/litestream.yml` (it is how
   Litestream looks up the replica), and `-o` is where the restored copy is written.

4. **Sanity-check the restored file** before trusting it, e.g.:
   ```bash
   sqlite3 /data/restored.sqlite3 "select count(*) from users; select count(*) from sailings;"
   ```

5. **Swap it into place.** Stop the app so nothing is writing, replace the database, then start
   again. From your workstation:
   ```bash
   bin/kamal app stop -d prod
   bin/kamal shell -d prod
   #   inside the container:
   mv /data/production.sqlite3 /data/production.sqlite3.bak   # keep the empty/old one aside
   mv /data/restored.sqlite3   /data/production.sqlite3
   exit
   bin/kamal app boot -d prod
   ```

6. **Verify the running site** — sign in and check recent data, and confirm
   `https://sailings.firstsoftware.cc/up` returns healthy (see [Monitoring](40-monitoring.md)).

### After a restore

- You only restored the **primary** database. The cache, queue, and cable databases are
  recreated automatically on boot (`db:prepare`), so there is nothing to restore for them.
- Once production is confirmed healthy and replicating again, run
  `bin/rails litestream:snapshots` to confirm new backups are being written to the recovered
  database.

---

## 4.6 A note on the data volume

Litestream protects the *primary database's contents*. The host volume
`"/var/data/sailings/storage:/data"` also holds any **Active Storage** uploads (e.g. photos),
which Litestream does **not** replicate. If uploads matter, ensure that host directory is
itself backed up off the server by other means — see the volume note in
[Deploying §3.4](20-deploying.md#34-what-runs-on-the-server).

---

[← Deploying](20-deploying.md) · [Manual index](README.md) · [Monitoring →](40-monitoring.md)
