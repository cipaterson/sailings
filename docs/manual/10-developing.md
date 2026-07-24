# 2. Developing

This chapter takes you from a bare machine to a running copy of Lady Nelson Sailings, then
explains how to run the tests, keep the code tidy, and find your way around the codebase.

It assumes you can program but does **not** assume you know Ruby, Rails, or Linux. Many
maintainers work on **Windows using WSL** (Windows Subsystem for Linux), so the setup is
written for that path; if you are on macOS or native Linux, skip [section 2.1](#21-windows-setup-with-wsl)
and start at [section 2.2](#22-install-ruby-342).

> **The short version, once your machine is ready:**
> ```bash
> git clone https://github.com/USER/sailings.git
> cd sailings
> # obtain the real config/master.key from a maintainer (see 2.4)
> bin/setup            # installs gems, prepares the database, starts the server
> ```
> The rest of this chapter explains each step and what to do when one of them fails.

---

## 2.1 Windows setup with WSL

WSL lets you run a real Linux environment (Ubuntu) inside Windows. Rails development is
much smoother on Linux than on native Windows, so this is the recommended path. You do not
need to be a Linux expert — you only need a handful of commands.

### Install WSL and Ubuntu

1. Open **PowerShell as Administrator** (right-click the Start button → *Terminal (Admin)*).
2. Run:
   ```powershell
   wsl --install
   ```
   This installs WSL and Ubuntu (the default Linux distribution). Reboot if prompted.
3. After the reboot, launch **Ubuntu** from the Start menu. The first time, it asks you to
   create a Linux username and password. This is separate from your Windows login — **remember
   it**, as you will use it for `sudo` (run-as-administrator) commands.

From here on, run every command in this chapter **inside the Ubuntu terminal**, not in
PowerShell or Command Prompt.

### Two rules that save a lot of pain

- **Keep the project inside the Linux home directory** (for example `~/sources/sailings`),
  **not** on the Windows drive under `/mnt/c/...`. Working under `/mnt/c` is much slower and
  causes file-permission and line-ending problems. Your Linux home is a fast, self-contained
  filesystem — treat it as where the code lives.
- **Edit with VS Code + the WSL extension.** Install [VS Code](https://code.visualstudio.com/)
  on Windows and its *WSL* extension. Then, from the Ubuntu terminal inside the project, run
  `code .` — VS Code opens on Windows but edits and runs everything inside Linux. You get a
  familiar editor without copying files back and forth.

### Install the build tools Ruby needs

Ruby and several gems compile native (C) code, so Ubuntu needs a compiler and a few
libraries first. Run this once:

```bash
sudo apt update
sudo apt install -y build-essential git curl \
  libssl-dev libyaml-dev zlib1g-dev libffi-dev \
  libsqlite3-dev libvips
```

(`sudo` runs a command as administrator and will ask for the Linux password you set above.)
`libsqlite3-dev` is for the database, and `libvips` is for image processing (member/vessel
photos via Active Storage).

---

## 2.2 Install Ruby 3.4.2

The project targets the exact Ruby version in [`.ruby-version`](../../.ruby-version):
**3.4.2**. The cleanest way to install and pin that version is a Ruby version manager. We
recommend **[mise](https://mise.jdx.dev/)** (this project is mise-aware), though `rbenv` or
`asdf` work equally well.

Install mise, then install Ruby:

```bash
curl https://mise.run | sh
exec $SHELL                 # reload your shell so `mise` is on the PATH
cd ~/sources/sailings       # inside the cloned project (see 2.3)
mise use ruby@3.4.2         # installs 3.4.2 and pins it for this project
ruby -v                     # should print ruby 3.4.2
```

Because the project contains a `.ruby-version` file, mise (and rbenv/asdf) automatically
switch to 3.4.2 whenever you `cd` into the directory — you should not have to think about it
again.

---

## 2.3 Get the code

Get the code from GitHub. If you are a maintainer, you can replace `cipaterson` with your own username.  If you are not, then you should fork the repository first into your own GitHub account, then clone your fork.

```bash
mkdir -p ~/sources && cd ~/sources
git clone https://github.com/cipaterson/sailings.git
cd sailings
```

Everything from here runs from inside this `sailings` directory.

---

## 2.4 Create `config/master.key` (required)

**The app will not boot without this file, and it is not in the repository.**

Rails keeps secrets — here, the DigitalOcean Spaces keys used for database backups — in an
**encrypted** file, [`config/credentials.yml.enc`](../../config/credentials.yml.enc), which
*is* committed to git. That file can only be decrypted with a matching **master key**. For
safety the master key is never committed: [`.gitignore`](../../.gitignore) excludes
`/config/*.key`, so each developer must place it manually.

At boot, the app decrypts the credentials (the Litestream backup configuration reads them),
so if `config/master.key` is missing or wrong you will get a decryption error such as
`ActiveSupport::MessageEncryptor::InvalidMessage` and the server will fail to start.

**What to do:**

1. Ask an existing maintainer for the project's master key. It is a single line of 32
   hexadecimal characters and should be shared through a password manager or another secure
   channel — never over email or chat, and never committed to git.
2. Save it as `config/master.key` in the project root (note: the path is `config/master.key`,
   directly under the repo — *not* `app/config/...`):
   ```bash
   printf '%s' 'PASTE_THE_32_CHARACTER_KEY_HERE' > config/master.key
   ```

> **Note.**
> If you ever genuinely need fresh credentials — e.g. a throwaway fork — you can run
> `bin/rails credentials:edit`, which generates a new `master.key` and a new encrypted file
> together.  BUT, this overwrites credentials.yml and you will need to find the secrets defined within if you want to, form example, use the email (Brevo API), etc.

---

## 2.5 First run

With Ruby installed and `config/master.key` in place, one command does the rest:

```bash
bin/setup
```

[`bin/setup`](../../bin/setup) is idempotent (safe to re-run). It:

1. installs the Ruby gem dependencies (`bundle install`),
2. prepares the SQLite databases (`bin/rails db:prepare` — creates them and runs migrations),
   and
3. starts the development server.

db:prepare also runs the seed task (if the DB was initialized, i.e. wasn't there already):

```bash
bin/rails db:seed
```

[`db/seeds.rb`](../../db/seeds.rb) creates one administrator account with every role:

| Email | Password | Roles |
|---|---|---|
| `admin@example.com` | `Password123!` | member, office_staff, crewing_operator, maintenance |

The site is then available at **http://localhost:3000**. Sign in with the account above.

### Running the server later

On subsequent days you usually just want the server, not the full setup:

```bash
bin/rails server      # or the shortcut: bin/dev
```

Stop it with `Ctrl-C`. There is no separate CSS/JavaScript build to run — assets are served
directly by Propshaft and importmap (see [Introduction §1.4](00-introduction.md#14-how-this-app-is-built-the-stack)).

---

## 2.6 Running the tests

The project uses **Minitest** (Rails' built-in framework). Tests run in parallel across your
CPU cores and use fixtures for sample data (see [`test/test_helper.rb`](../../test/test_helper.rb)).

```bash
bin/rails test                       # all unit and integration tests
bin/rails test test/models/user_test.rb        # one file
bin/rails test test/models/user_test.rb:42     # one test, by line number
```

### System tests (browser tests)

System tests drive a real browser with Capybara + Selenium:

```bash
bin/rails test:system
```

You do **not** need to install Chrome yourself: Selenium Manager automatically downloads a
private "Chrome for Testing" build, and the suite is configured to point at it (see the
comment in [`test/application_system_test_case.rb`](../../test/application_system_test_case.rb)).
The tests run headless (no visible window).

> **WSL note.** The auto-downloaded Chrome is a Linux binary and expects the usual desktop
> libraries, which a minimal Ubuntu install lacks. If a system test fails with an error about
> a missing shared library (for example `libnss3.so` or `libgbm.so`), install Chrome's
> runtime dependencies once:
> ```bash
> sudo apt install -y libnss3 libatk-bridge2.0-0 libgtk-3-0 libgbm1 libasound2
> ```

---

## 2.7 Linting and security checks

These are the same checks that run in CI (see [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml)),
so run them before pushing to github to avoid a red build:

```bash
bin/rubocop                      # style/lint (rubocop-rails-omakase house style)
bin/rubocop -a                   # auto-correct what it safely can
bin/brakeman                     # static security analysis of the Rails code
bundle exec bundler-audit        # checks gems for known vulnerabilities
bin/importmap audit              # checks pinned JavaScript for known vulnerabilities
```

Style is governed by [`.rubocop.yml`](../../.rubocop.yml), which inherits the Rails opinionated
"omakase" ruleset. Match the surrounding code rather than adding new configuration.

---

## 2.8 How the code is organized

The layout follows standard Rails conventions (see [Introduction §1.3](00-introduction.md#13-ruby-on-rails-in-brief)).
The directories you will touch most:

| Path | What lives here |
|---|---|
| `app/models/` | The domain: `Sailing`, `SailingParticipant`, `User`, `Contact`, `MaintenanceTask`, `Session` |
| `app/controllers/` | Request handling — one controller per resource (voyages, crew, members, maintenance) |
| `app/views/` | ERB HTML templates, grouped by controller |
| `app/javascript/controllers/` | Stimulus controllers (small front-end behaviours) |
| `app/jobs/` | Background jobs run by Solid Queue (e.g. sending crew emails and SMS) |
| `app/assets/stylesheets/application.css` | Styles (no preprocessor) |
| `config/routes.rb` | URL → controller mapping; a good map of every feature |
| `config/` | Application, database, deployment, and Litestream configuration |
| `db/migrate/`, `db/schema.rb` | Database migrations and the current schema |
| `test/` | Minitest tests and fixtures; `test/system/` holds browser tests |

A good way to orient yourself in an unfamiliar feature is to start at
[`config/routes.rb`](../../config/routes.rb), find the route, open the matching controller
in `app/controllers/`, and follow it to the model and view.

### Everyday commands

```bash
bin/rails console          # interactive Ruby session with the app loaded
bin/rails db:migrate       # apply new migrations after pulling changes
bin/rails routes           # list every route
bin/rails db:seed          # create the initial admin account (unless it already exists)
```

---

## 2.9 Common setup problems

| Symptom | Likely cause and fix |
|---|---|
| `MessageEncryptor::InvalidMessage` / "credentials" error at boot | `config/master.key` is missing or wrong — see [§2.4](#24-create-configmasterkey-required) |
| `bundle install` fails compiling a native gem | Build tools/libraries not installed — re-run the `apt install` in [§2.1](#install-the-build-tools-ruby-needs) |
| `ruby -v` shows the wrong version | Version manager not active; run `mise use ruby@3.4.2` (or reopen the terminal) inside the project |
| System test fails with `cannot find library ...` | Install Chrome's runtime libraries — see the WSL note in [§2.6](#system-tests-browser-tests) |
| Very slow file access / permission oddities | The project is under `/mnt/c/...`; move it into your Linux home (`~`) — see [§2.1](#two-rules-that-save-a-lot-of-pain) |

---

[← Back to Introduction](00-introduction.md) · [Manual index](README.md) · [External Setup →](20-external-setup.md)
