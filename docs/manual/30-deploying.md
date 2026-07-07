# 4. Deploying

This chapter explains how a version of Lady Nelson Sailings gets from your machine onto a
live server. Deployment uses **[Kamal](https://kamal-deploy.org/)**, which packages the app
as a **Docker** image and runs it on a plain Linux server over SSH.

If you have not deployed before, read [§4.1](#41-how-deployment-works) and
[§4.2](#42-prerequisites) first, then follow [§4.6](#46-deploying).

---

## 4.1 How deployment works

Kamal does four things each time you deploy:

1. **Builds a Docker image** of the app from the [`Dockerfile`](../../Dockerfile) (a
   multi-stage build on `ruby:3.4.2-slim`; it installs gems, precompiles assets, and runs as
   a non-root `rails` user).
2. **Pushes** that image to a Docker **registry**.
3. **Pulls and runs** the image on the target server(s) over SSH.
4. **Cuts over** traffic to the new container through Kamal's built-in proxy, with zero
   downtime, and keeps the previous version so you can roll back.

The container serves the app through **Thruster** (HTTP caching/compression in front of Puma)
on port 80. Background jobs run **inside** that same web process because
`SOLID_QUEUE_IN_PUMA=true` — there is no separate worker to deploy.

### Configuration files

Kamal always reads [`config/deploy.yml`](../../config/deploy.yml) as the **base**
configuration. Passing a **destination** with `-d <name>` merges `config/deploy.<name>.yml`
on top of the base. So `bin/kamal deploy` deploys the base config, while
`bin/kamal deploy -d prod` deploys the base **plus** the production overrides. The
destinations are described in [§4.3](#43-deployment-destinations).

---

## 4.2 Prerequisites

You run Kamal from your own machine (inside WSL, if you are on Windows — see
[Developing §2.1](10-developing.md#21-windows-setup-with-wsl)). Before your first deploy you need:

- **Docker installed locally** — Kamal builds the image on your machine.
- **`config/master.key` present** — it is read at deploy time (see [§4.5](#45-secrets-and-configuration)).
- **SSH access to the server** — passwordless (key-based) login for the SSH user configured
  for the destination (`root`). Test it with `ssh root@<host>` before deploying. (see [§4.10](#410-connecting-to-your-server))
- **A reachable Docker registry.** All destinations are configured to use a registry at
  `localhost:5555` (see the `registry:` block in `config/deploy.yml`), this is standard in kamal 2.8 or later. If you move to a hosted registry (Docker Hub, GHCR, DigitalOcean), update that
  block and add the registry password to [`.kamal/secrets-common`](../../.kamal/secrets-common).
- **The `kamal` gem**, which is bundled with the project — invoke it as `bin/kamal`.

---

## 4.3 Deployment destinations

Four destinations are defined. **Staging is the default** (no `-d` flag). Only **production**
runs continuous database backups.

| Destination | Command | Host | Service / image | Arch | SSH user | SSL | Litestream backup |
|---|---|---|---|---|---|---|---|
| **Staging** (default) | `bin/kamal deploy` | `staging.firstsoftware.cc` | `staging` | amd64 | root | Let's Encrypt | off |
| **Production** | `bin/kamal deploy -d prod` | `sailings.firstsoftware.cc` | `sailings` | amd64 | root | Let's Encrypt | **on** (`LITESTREAM_REPLICATE=true`) |
| **Raspberry Pi** | `bin/kamal deploy -d raspi` | `rails.lan` | `staging` | arm64 | `sailings` | Let's Encrypt | off |
| **IP host** | `bin/kamal deploy -d IP` | `34.129.63.249` | `staging` | amd64 | root | off (plain HTTP) | off |

Notes:

- The **`raspi`** and **`IP`** destinations only override the host (and arch/SSH/SSL); they
  inherit the *staging* service name, image, and environment from the base config. They are
  convenience targets — a local Raspberry Pi and a bare IP address — for testing the same
  build on different hardware.
- **Continuous backup is deliberately production-only.** The Litestream replica location is
  shared by all destinations (in the base config) so any of them can *restore* from the
  backup, but only production sets `LITESTREAM_REPLICATE=true` to *write* to it. See
  [Backup & Restore](40-backup-restore.md).

---

## 4.4 What runs on the server

- **Persistent storage.** The four SQLite databases (primary, cache, queue, cable) and any
  Active Storage uploads (none so far) live on a host volume mounted into the container:
  `"/var/data/sailings/storage:/data"`. The container is disposable; this directory is the
  data that must survive redeploys and is itself backed up off the server.
- **Database prepare on boot.** The container's entrypoint
  ([`bin/docker-entrypoint`](../../bin/docker-entrypoint)) runs `bin/rails db:prepare` when it
  starts the server, so migrations are applied automatically on each deploy.
- **TLS.** For staging and production, Kamal's proxy obtains and renews a Let's Encrypt
  certificate for the configured host. The `IP` destination runs plain HTTP (`ssl: false`).

---

## 4.5 Secrets and configuration

Environment variables reach the container in two ways (see the `env:` block in
`config/deploy.yml`):

- **`clear`** — non-secret values baked into the deploy config: `SOLID_QUEUE_IN_PUMA`, the
  `RAILS_LOG_LEVEL`, the Litestream replica location (`LITESTREAM_REPLICA_BUCKET`,
  `_ENDPOINT`, `_REGION`), and — production only — `LITESTREAM_REPLICATE=true`.
- **`secret`** — `RAILS_MASTER_KEY`, sourced by
  [`.kamal/secrets-common`](../../.kamal/secrets-common), which reads it straight from your
  local `config/master.key` (`RAILS_MASTER_KEY=$(cat config/master.key)`). This is why the
  key file must be present locally when you deploy.

The **DigitalOcean Spaces access keys** used for backups are *not* passed as environment
variables. They live inside the encrypted Rails credentials and are decrypted at runtime with
the master key (see [`config/initializers/litestream.rb`](../../config/initializers/litestream.rb)).
Keeping them in credentials means they never travel through Kamal's environment or command
line. To view or change them:

```bash
bin/rails credentials:edit
```

---

## 4.6 Deploying

### First time onto a new server (`setup`)

`setup` provisions the server (installs Docker and the Kamal proxy if needed) and performs the
first deploy:

```bash
bin/kamal setup            # staging (default)
bin/kamal setup -d prod    # production
```

### Routine deploys

Once a server has been set up, deploying a new version is just:

```bash
bin/kamal deploy           # staging (default)
bin/kamal deploy -d prod   # production
```

By default Kamal builds from the current git `HEAD`, so commit your changes
first. A typical release is: merge to `main` → `bin/kamal deploy` to staging → verify → then
`bin/kamal deploy -d prod`.

You can build from your working directory if you change context in the `deploy.yml` config to:

```yaml
# Configure the image builder.
builder:
  arch: amd64
  # This sets the build context for the Docker image, default is HEAD of git repo.
  context: "."
```
**Remember** to comment it out again (or `git restore config/deploy.yml`) before you commit.

> **Reminder:** the `-d prod` destination is the only one that carries the production host and
> turns on continuous backups. Omitting `-d prod` deploys to **staging**, not production.

---

## 4.7 Operating a running deployment

The base deploy.yml config defines aliases (the `aliases:` block) so you don't have to remember the long
forms. Add `-d prod` to target production:

```bash
bin/kamal logs -d prod            # tail application logs
bin/kamal console -d prod         # Rails console inside a container
bin/kamal shell -d prod           # a bash shell inside a container
bin/kamal dbc -d prod             # rails dbconsole (SQLite prompt)
```

Other useful Kamal commands:

```bash
bin/kamal app boot -d prod        # (re)start the app containers
bin/kamal rollback -d prod        # switch back to the previous image
bin/kamal proxy reboot -d prod    # restart the TLS proxy
bin/kamal details -d prod         # show running containers
```

If a deploy fails partway, `bin/kamal rollback` returns to the previous known-good version;
then diagnose the failed build or boot locally before trying again. See
[Troubleshooting](60-troubleshooting.md).

---

## 4.8 Pre-deploy checklist

- [ ] Changes committed to git (by default Kamal builds from `HEAD` in the git repo, NOT from the working directory). If you deploy and nothing changes, perhaps you have forgotten to commit your changes.
- [ ] CI green on the branch (tests, RuboCop, Brakeman — see [Developing §2.7](10-developing.md#27-linting-and-security-checks)).
- [ ] `config/master.key` present locally.
- [ ] Docker running and the `localhost:5555` registry reachable.
- [ ] SSH to the target host works without a password.
- [ ] Deployed and verified on **staging** first, then `-d prod`.
- [ ] After a production deploy, confirmed the app answers on `https://sailings.firstsoftware.cc/up` (see [Monitoring](50-monitoring.md)).

---

## 4.9 Rollback

This is a key step in troubleshooting: if a deploy fails, roll back to the previous version and diagnose the issue locally (and/or in staging) before retrying production.

Kamal rollback command **requires a image version** to roll back to.  Find the previous version with:
```bash
$ bin/kamal app containers -q
CONTAINER ID   IMAGE                                                             CREATED        STATUS
98bd25e46f79   localhost:5555/staging:8d98cb7ec1bdc3b2174ffe2f4e254618b4655c9c   3 hours ago    Up 3 hours
428ec8628b68   localhost:5555/staging:763a123ee82523ca12d32eb06ca35fa7c97e7677   3 hours ago    Exited (143) 3 hours ago
6c9e4961e53e   6b6175ba4331
```

Usually it will be the second container listed.  Rollback with:
```bash
$ bin/kamal rollback 763a123ee82523ca12d32eb06ca35fa7c97e7677
```

REMEMBER - these commands are working on the staging deployment destination (the default).  To rollback the production server, use **-d prod**:
```bash
$ bin/kamal rollback 763a123ee82523ca12d32eb06ca35fa7c97e7677 -d prod
```

[← External Setup](20-external-setup.md) · [Manual index](README.md) · [Backup & Restore →](40-backup-restore.md)
