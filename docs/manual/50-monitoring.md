# 6. Monitoring

This chapter covers how to tell whether Lady Nelson Sailings is healthy, where to look when
you suspect it isn't.

Monitoring can be done by an external uptime monitor (e.g. **UptimeRobot**, see [§3.6](#36 Monitoring)) or by running a handful of **checks you run on demand**.

---

## 6.1 The health-check endpoint (`/up`)

Rails exposes a health check at **`GET /up`** (see [`config/routes.rb`](../../config/routes.rb)):

- It returns **HTTP 200** if the app boots and handles a request with no exception, and
  **500** otherwise.
- It is meant for **load balancers and uptime monitors** to poll.
- It is **silenced from the logs** (`config.silence_healthcheck_path = "/up"` in
  [`config/environments/production.rb`](../../config/environments/production.rb)), so frequent
  polling does not flood the log.

Quick manual check:

```bash
curl -i https://sailings.firstsoftware.cc/up      # production
curl -i https://staging.firstsoftware.cc/up       # staging
```

A `200 OK` means the app is up and its database connections work. A `500`, a timeout, or a TLS
error means something is wrong — go to the logs ([§6.2](#62-application-logs)) and
[Troubleshooting](60-troubleshooting.md).

> **Recommended:** point an external uptime monitor (e.g. **UptimeRobot**, Better Stack, or a
> DigitalOcean/Cloudflare check) at `https://sailings.firstsoftware.cc/up` so you are alerted
> when the site goes down.

---

## 6.2 Application logs

The app logs to **STDOUT**, tagged with the request id, at the level set by `RAILS_LOG_LEVEL`
(`info` in production; see [`config/deploy.prod.yml`](../../config/deploy.prod.yml)). Docker
captures STDOUT, so Kamal can show it. File logging is intentionally disabled.

Read the logs with Kamal (the `logs` alias tails and follows):

```bash
bin/kamal logs -d prod            # follow production logs
bin/kamal logs -d prod -n 200     # last 200 lines, then exit
bin kamal logs                    # follow the logs in staging (default destination)
```

Each line carries the request id tag, so you can trace all the log lines belonging to a single
request. Because health checks are silenced, the log is mostly real traffic and errors.

### Turning up the detail temporarily

To debug a production issue you can raise the log level to `debug`. Set
`RAILS_LOG_LEVEL: debug` in the `env.clear` block of `config/deploy.prod.yml` and redeploy (or
`bin/kamal env push -d prod`), then **revert it** — `debug` logs can include
personally-identifiable information and is noisy.

---

## 6.3 Is it healthy? A quick round

When you want to confirm production is fully well, not just answering:

1. **Reachable:** `/up` returns 200 ([§6.1](#61-the-health-check-endpoint-up)).
2. **Containers running:** `bin/kamal details -d prod` shows the app (and proxy) up.
3. **No error spikes:** `bin/kamal logs -d prod -n 200` is free of exceptions/500s.
4. **Jobs flowing:** background jobs aren't backing up ([§6.4](#64-background-jobs-solid-queue)).
5. **Backups current:** replication is still writing ([§6.5](#65-backups-and-replication)).
6. **Disk not full:** the data volume has room ([§6.6](#66-gaps-worth-closing)).

---

## 6.4 Background jobs (Solid Queue)

Jobs (crew emails and SMS, and other deferred work) run on **Solid Queue**, **inside the web
process** (`SOLID_QUEUE_IN_PUMA=true`). There is no separate worker and — because the
`mission_control-jobs` dashboard gem is commented out in the [`Gemfile`](../../Gemfile) — no
web UI for jobs.

Inspect the queue from the Rails console:

```bash
bin/kamal console -d prod
```

```ruby
SolidQueue::Job.count               # total jobs
SolidQueue::ReadyExecution.count    # waiting to run — should stay low
SolidQueue::FailedExecution.count   # failures — investigate if non-zero
SolidQueue::FailedExecution.last&.error   # the most recent failure detail
```

A growing `ReadyExecution` backlog or a rising `FailedExecution` count is the signal that jobs
are stuck — check the logs for the failing job class. (If richer job visibility becomes
worthwhile, uncommenting `mission_control-jobs` adds a mountable dashboard.)

---

## 6.5 Backups and replication

Litestream replication is part of what "healthy" means in production. Confirm it is still
shipping the database to object storage — from a production container:

```bash
bin/kamal shell -d prod
bin/rails litestream:snapshots -- --database=/data/production.sqlite3
```

Recent snapshots mean backups are current. The full procedure, including verifying a backup is
restorable, is in [Backup & Restore §5.4](40-backup-restore.md#54-checking-the-backup-is-healthy).

---

## 6.6 Gaps worth closing

Be aware of what is **not** monitored today, so no one assumes coverage that doesn't exist:

- **No error tracking / APM.** There is no Sentry, Honeybadger, Datadog, or similar, so
  exceptions are only visible by reading the logs. Errors are not aggregated or alerted on.
- **No metrics.** No request-rate, latency, or resource dashboards.
- **No disk-space alerting.** The four SQLite databases and Active Storage uploads grow on the
  `/var/data/sailings/storage` volume. Check headroom periodically:
  ```bash
  bin/kamal shell -d prod
  df -h /data && du -sh /data/*
  ```
In the DigitalOcean control panel, the Insights tab for the app provides a high-level view of the app's health, including disk space usage and resource metrics.

For a small volunteer-run site, an **external uptime monitor on `/up`** plus **occasional log
and disk checks** is a reasonable baseline; error tracking is the natural next step if incidents
become hard to diagnose from logs alone.

---

[← Backup & Restore](40-backup-restore.md) · [Manual index](README.md) · [Troubleshooting →](60-troubleshooting.md)
