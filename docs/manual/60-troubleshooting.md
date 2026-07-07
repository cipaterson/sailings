# 7. Troubleshooting

This chapter is a symptom-first guide to the problems you are most likely to hit, in
development and in production. It pulls together failure modes referenced across the other
chapters and adds the diagnostic steps for each.

Start with [§7.1](#71-first-steps-any-problem); most investigations begin the same way.

---

## 7.1 First steps (any problem)

Before diving in, gather the basics — they usually point straight at the cause:

1. **Is it up?** `curl -i https://sailings.firstsoftware.cc/up` — 200 vs 500 vs timeout tells
   you a lot (see [Monitoring §6.1](50-monitoring.md#61-the-health-check-endpoint-up)).
2. **What do the logs say?** `bin/kamal logs -d prod -n 200` — the exception and its request-id
   tag are usually right there (see [Monitoring §6.2](50-monitoring.md#62-application-logs)).
3. **Are the containers running?** `bin/kamal details -d prod`.
4. **What changed?** A problem that started just after a deploy points at the new release —
   consider `bin/kamal rollback -d prod` first, then diagnose calmly.

Throughout this chapter, drop `-d prod` to target **staging** (the default destination).

---

## 7.2 Local development

| Symptom | Cause & fix |
|---|---|
| `ActiveSupport::MessageEncryptor::InvalidMessage` / credentials error on boot | `config/master.key` missing or wrong — see [Developing §2.4](10-developing.md#24-create-configmasterkey-required) |
| `bundle install` fails building a native gem (sqlite3, ffi, vips) | Build tools/libraries missing — re-run the `apt install` from [Developing §2.1](10-developing.md#install-the-build-tools-ruby-needs) |
| `ruby -v` reports the wrong version | Version manager not active — `mise use ruby@3.4.2` inside the project, or reopen the terminal |
| System test: `cannot find Chrome binary` / missing `libnss3.so` etc. | Chrome runtime libs missing under WSL — see [Developing §2.6](10-developing.md#system-tests-browser-tests) |
| `bin/rails server` fails: "port 3000 already in use" | A stale server is running. Find and stop it: `lsof -i :3000` then `kill <pid>` |
| Pages error about a pending migration | `bin/rails db:migrate` (after pulling new code) |
| Very slow file access / odd permissions (WSL) | Project is under `/mnt/c/...`; move it into the Linux home — [Developing §2.1](10-developing.md#two-rules-that-save-a-lot-of-pain) |

---

## 7.3 Deploys that fail

Work through the stage Kamal failed at (build → push → connect → boot):

- **Image build fails.** Read the build output. It is a normal `docker build` against the
  [`Dockerfile`](../../Dockerfile); reproduce locally with `docker build -t sailings-test .`
  to iterate faster. A gem/asset error here is the usual cause.
- **Cannot push / pull the image (registry).** All destinations use a registry at
  `localhost:5555`; if it is unreachable the push fails. Ensure the local registry is running
  and reachable — see [Deploying §4.2](30-deploying.md#42-prerequisites).
- **SSH / connection refused.** Kamal needs passwordless SSH as the destination's user
  (`root` for most). Test `ssh <user>@<host>` directly; fix keys before
  retrying, see [Deploying §3.2](30-deploying.md#32-connecting-to-your-server).
- **Deploys but the new version is unhealthy** (cutover fails or `/up` returns 500 after
  release). Roll back and diagnose the boot problem ([§7.4](#74-app-wont-boot--500-on-up)):
  ```bash
  bin/kamal rollback -d prod
  ```

---

## 7.4 App won't boot / 500 on `/up`

A container that starts but fails the health check almost always trips on one of these — check
`bin/kamal logs -d prod` for the exception:

- **Missing/incorrect master key on the server.** `RAILS_MASTER_KEY` is sourced from your local
  `config/master.key` at deploy time ([Deploying §4.5](30-deploying.md#45-secrets-and-configuration)).
  If it is absent or wrong, the app cannot decrypt credentials at boot and crashes. Confirm the
  key file is present locally and redeploy.
- **Failed migration.** The entrypoint runs `db:prepare` on boot
  ([Deploying §4.4](30-deploying.md#44-what-runs-on-the-server)); a bad migration aborts startup.
  The log shows which one — fix it and redeploy.
- **Volume permission errors.** The container runs as a non-root user (uid 1000). If the host
  volume `"/var/data/sailings/storage"` is owned such that uid 1000 cannot write, the app can't
  open its SQLite files. Check ownership on the host and correct it (files under `/data` must be
  writable by uid 1000).

---

## 7.5 Database (SQLite) issues

- **"database is locked" (`SQLite3::BusyException`).** SQLite allows one writer at a time; under
  brief contention a writer can time out. The connection timeout is set in
  [`config/database.yml`](../../config/database.yml) (`timeout: 5000` ms). Occasional locks
  under load are expected; persistent locking suggests a long-running write or a stuck process —
  check the logs and `bin/kamal details`.
- **Disk full.** The four databases and Active Storage uploads share the `/data` volume. If it
  fills, writes fail. Check headroom and see what is large:
  ```bash
  bin/kamal shell -d prod
  df -h /data && du -sh /data/*
  ```
- **Which database?** Only `production.sqlite3` holds real data; the `_cache`, `_queue`, and
  `_cable` files are regenerable. If one of the latter is corrupt you can usually delete it and
  let Rails recreate it on the next boot (do **not** do this to the primary — restore it
  instead, see [Backup & Restore](40-backup-restore.md)).

---

## 7.6 Background jobs not running

Jobs (crew email and SMS) run on **Solid Queue inside Puma**, enabled by
`SOLID_QUEUE_IN_PUMA=true`.

- If jobs never run, confirm that variable is set for the destination (it is, in the deploy
  configs) and that the app booted cleanly.
- Inspect the queue from the console ([Monitoring §6.4](50-monitoring.md#64-background-jobs-solid-queue)):
  ```ruby
  SolidQueue::ReadyExecution.count          # a growing backlog = jobs stuck
  SolidQueue::FailedExecution.count
  SolidQueue::FailedExecution.last&.error   # why the last one failed
  ```
- A rising `FailedExecution` count points at an error inside a specific job class — the error
  string and the logs name it.

---

## 7.7 Email or SMS not being sent

Both go out through background jobs, so a failure usually surfaces as a `FailedExecution`
([§7.6](#76-background-jobs-not-running)) and in the logs.

- **Email** is delivered via **Brevo** (a custom delivery method,
  [`config/initializers/brevo_delivery.rb`](../../config/initializers/brevo_delivery.rb); mailers
  send from `no-reply@sailings.firstsoftware.cc`). `raise_delivery_errors` is **on** in
  production, so delivery problems raise and are logged rather than failing silently. Check that
  the Brevo API credentials are present and valid in Rails credentials (`bin/rails credentials:edit`,
  key `brevo`) and look for API errors in the logs.
- **SMS** is sent by `SendSmsBatchJob` via `MobileMessageService`, configured from Rails
  credentials (key `mobile_message`). If SMS stops, check that job's failures and confirm the
  SMS provider credentials and account balance.
- **Nothing queued at all?** Confirm the action actually enqueued the job (the controller shows
  a "queued for N …" notice) and that jobs are processing at all ([§7.6](#76-background-jobs-not-running)).

---

## 7.8 Backup and restore problems

- **Replication not producing snapshots.** Continuous replication runs **only** where
  `LITESTREAM_REPLICATE=true` — production. Confirm you are checking production, then verify
  recent snapshots (`bin/rails litestream:snapshots -- --database=/data/production.sqlite3`).
  Missing snapshots usually mean bad/absent Spaces credentials (key `litestream` in Rails
  credentials) or the plugin not loading — check boot logs for Litestream errors. See
  [Backup & Restore §5.4](40-backup-restore.md#54-checking-the-backup-is-healthy).
- **Restore can't reach the replica.** The destination needs both the replica settings (present
  on all destinations) and the Spaces keys (decrypted via the master key). Run the restore from
  inside a container (`bin/kamal shell`) so the Rails environment supplies them.

---

## 7.9 TLS / certificate issues

Staging and production terminate TLS at Kamal's proxy using Let's Encrypt for the configured
host. If HTTPS fails (untrusted or missing certificate):

- Confirm DNS for the host points at the server and ports 80/443 are open — Let's Encrypt must
  reach the server to issue/renew.
- Inspect and restart the proxy if needed:
  ```bash
  bin/kamal proxy details -d prod
  bin/kamal proxy reboot -d prod
  ```
- The `IP` destination is intentionally plain HTTP (`ssl: false`) — HTTPS is not expected there.

---

## 7.10 When you're stuck

- Reproduce on **staging** if at all possible before touching production.
- Get an interactive session to poke around: `bin/kamal console -d prod` (Rails) or
  `bin/kamal shell -d prod` (bash).
- If a release is implicated and you can't immediately see why, **roll back first**
  (`bin/kamal rollback -d prod`) to restore service, then investigate from a known-good state.

---

[← Monitoring](50-monitoring.md) · [Manual index](README.md)
