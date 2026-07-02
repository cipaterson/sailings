# Lady Nelson Sailings — Operations & Development Manual

## 1. Introduction

### 1.1 About this manual

This manual is the reference for everyone who builds, runs, and maintains the **Lady
Nelson Sailings** web application. It is written for a developer who is comfortable
programming but may be new to Ruby on Rails and to this codebase, so it explains both
the framework in general terms and the specifics of this site.

The manual is organised into sections, each in its own file in `docs/manual/`:

| Section | File | Covers |
|---|---|---|
| Introduction | [`00-introduction.md`](00-introduction.md) | This document — what the app is and how the manual is arranged |
| Developing | [`10-developing.md`](10-developing.md) | Local setup, running the app and tests, code layout, conventions |
| External Setup | [`20-external-setup.md`](20-external-setup.md) | External services and infrastructure the app depends on |
| Deploying | [`30-deploying.md`](30-deploying.md) | Kamal, the staging and production destinations, releases |
| Backup & Restore | [`40-backup-restore.md`](40-backup-restore.md) | Litestream replication to object storage and how to restore |
| Monitoring | [`50-monitoring.md`](50-monitoring.md) | Health checks, logs, and how to tell the app is healthy |
| Troubleshooting | [`60-troubleshooting.md`](60-troubleshooting.md) | Common failures and how to diagnose them |

If you are brand new, read this introduction, then **Developing**, and keep the others
handy for when you deploy or when something breaks.

### 1.2 What the site is for

Lady Nelson Sailings is the membership and voyage-management system for **Lady Nelson
Tasmania**, the volunteer organisation that operates the heritage tall ship *Lady Nelson*
out of Hobart. It replaces spreadsheets and email threads with a single place where the
office and crew can:

- **Schedule voyages** ("sailings") — day sails, training sails, maintenance and
  engineering runs, and paid charters — and view them as a list or a month/week/day
  calendar.
- **Crew the voyages** — members register an Expression of Interest (EOI); office and
  crewing staff accept or decline crew, update statuses in bulk, and notify crew by email
  and SMS. A printable crew manifest (PDF) and CSV exports are produced for each voyage.
- **Keep the member directory** — full profiles with contact and next-of-kin details,
  membership type, fees, and the safety and sailing qualifications the ship requires
  (ESS, MED, WWVP, First Aid, Coxswain, Food Handling), each with issue and expiry dates.
- **Track charters** — charterer contact details, quotes, deposits, and payment status.
- **Log maintenance** — record and follow facility and vessel maintenance tasks by
  priority and status.

Members see their own voyage history and registrations through a personal "My
Registrations" dashboard. Access is controlled by **roles** held as a bitmask on each
user — `member`, `office_staff`, `crewing_operator`, and `maintenance` — so people only
see and change what their role allows.

### 1.3 Ruby on Rails in brief

The application is built with **Ruby on Rails**, a long-established open-source web
framework written in the Ruby language. A few ideas explain most of how the code is laid
out, and they are worth knowing before you open the project:

- **Convention over configuration.** Rails favours standard names and locations over
  wiring things together by hand. Models live in `app/models`, controllers in
  `app/controllers`, views in `app/views`, and Rails connects them automatically. Once
  you know the conventions, you can find your way around any Rails app quickly.
- **MVC (Model–View–Controller).** A **model** is a Ruby class backed by a database table
  (for example `Sailing` maps to the `sailings` table) and holds the data and business
  rules. A **controller** handles an incoming web request, loads or changes models, and
  chooses a response. A **view** is the HTML template rendered back to the browser. A
  **route** (in `config/routes.rb`) maps a URL to a controller action.
- **Active Record & migrations.** Rails' Active Record layer lets you work with database
  rows as Ruby objects instead of writing SQL. Schema changes are made through
  **migrations** — small, ordered Ruby files in `db/migrate` — so the database structure
  is version-controlled alongside the code.
- **The full stack ships in the box.** Rails includes the database layer, background
  jobs, caching, real-time updates over WebSockets, testing, and asset handling, so a
  single Rails app covers what would otherwise be several separate services.

If you have not used Rails before, the official [Rails Guides](https://guides.rubyonrails.org)
are the best companion to this manual; here we focus on how this particular app uses the
framework.

### 1.4 How this app is built (the stack)

This is a modern **Rails 8.1** application running on **Ruby 3.4.2**, and it deliberately
keeps the number of moving parts small:

- **Database — SQLite everywhere.** Unusually, the app uses SQLite in every environment,
  including production. Production actually uses *four* SQLite databases stored under
  `storage/`: the main application database plus three that back Rails' own subsystems —
  cache, background-job queue, and WebSockets (see below). Using SQLite keeps operation
  simple: there is no separate database server to run.
- **Hotwire (Turbo + Stimulus) for the front end.** Rather than a separate JavaScript
  application, the UI uses Hotwire: **Turbo** updates pages by sending HTML fragments over
  the wire, and **Stimulus** adds small, focused sprinkles of JavaScript behaviour. Pages
  feel dynamic without a heavyweight client-side framework.
- **No Node build step.** Assets are served by **Propshaft**, and JavaScript modules are
  managed with **importmap** — the browser loads ES modules directly. There is no
  npm/yarn/webpack build to install or run.
- **The "Solid" trio, all on the database.** Background jobs run on **Solid Queue** (which
  runs inside the web server process, Puma, in this deployment), caching uses **Solid
  Cache**, and real-time features use **Solid Cable**. All three are backed by SQLite,
  which is why there is no Redis or separate job worker to manage.
- **A few key gems** round it out: `bcrypt` (password hashing), `prawn` (PDF manifests),
  `money-rails` (charter pricing), `litestream` (database backup), and `kamal` (deployment).

### 1.5 Running and operating it, at a glance

- **Local development** uses `bin/rails server` to run the app and `bin/rails test` /
  `bin/rails test:system` to run the test suites (Minitest, with Capybara + headless
  Chrome for system tests). Full instructions are in [**Developing**](10-developing.md).
- **External services** — the app relies on infrastructure and accounts outside the codebase
  (servers, object storage, DNS, email and SMS providers). See [**External Setup**](20-external-setup.md).
- **Deployment** uses **Kamal**, which builds a Docker image and ships it to a server.
  There are two main destinations: **staging** at `staging.firstsoftware.cc` (the default)
  and **production** at `sailings.firstsoftware.cc`. See [**Deploying**](30-deploying.md).
- **Backups** are continuous: **Litestream** streams the production database to
  **DigitalOcean Spaces** (S3-compatible object storage) so it can be restored after a
  server loss. See [**Backup & Restore**](40-backup-restore.md).
- **Monitoring** starts with the `GET /up` health-check endpoint and the application's
  logs. See [**Monitoring**](50-monitoring.md), and [**Troubleshooting**](60-troubleshooting.md)
  for common problems.

### 1.6 Related documents

- `README.md` — a quick-start summary and command reference at the repo root.
- `CLAUDE.md` — conventions and architecture notes used when working in this codebase.

This manual expands on both, with the operational detail needed to run the site in
production.
