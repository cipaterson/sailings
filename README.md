# Sailings

A Rails web application for managing sailing voyages and club membership for **Lady Nelson Tasmania**. It handles voyage scheduling, crew participation, member records, qualifications, and facility maintenance.

## Features

- **Voyages** — Create and manage sailing events. List and calendar views (month, week, day). Crew manifest PDF export. CSV export.
- **Crew registration** — Members register interest (EOI) for voyages; office staff accept or manage crew. Bulk status updates from the crew management view.  Emails and SMSs can be sent to crew.
- **Member directory** — Full member profiles with contact details, next-of-kin, membership info, qualifications (ESS, MED, WWVP, First Aid, Coxswain, Food Handling), training dates, and fees tracking. Role-based access control. CSV export.
- **My Registrations** — Personal dashboard showing a member's voyage history and participation status.
- **Maintenance tasks** — Log and track facility maintenance issues with priority and status.
- **Charter contacts** — Contact details attached to charter sailings.

## Tech Stack

- **Ruby** 3.4.2, **Rails** 8.1
- **Database** SQLite (all environments) — primary, cache, queue, and cable databases
- **Asset pipeline** Propshaft + importmap (no Node/npm required)
- **Frontend** Hotwire (Turbo + Stimulus)
- **Background jobs** Solid Queue (runs inside Puma)
- **Caching** Solid Cache · **WebSockets** Solid Cable
- **Deployment** Kamal (Docker)

## Development Setup

### Prerequisites

Install Ruby 3.4.2 and Rails following the [official guide](https://guides.rubyonrails.org/install_ruby_on_rails.html).

### Getting started

>Important Note: There are secrets (API keys, etc) encoded by a master key (which MUST NOT be committed to github).  The master key must be manually created at  `./app/config/master.key`.


```bash
git clone https://github.com/chrispa/sailings.git
cd sailings
bundle install
echo "PASTE_THE_32_CHARACTER_KEY_HERE" > ./app/config/master.key
bin/rails db:create db:migrate db:seed
bin/rails server
```

`db:seed` loads sample data with this user (password: `Password123!`):

| Email | Role |
|---|---|
| `admin@example.com` | All roles |

## Common Commands

```bash
bin/rails server          # Start development server
bin/rails test            # Run unit/integration tests
bin/rails test:system     # Run system tests (requires Chrome)
bin/rails db:migrate      # Run pending migrations
bin/rails console         # Open Rails console
bin/rubocop               # Lint
bin/brakeman              # Security audit
```

## Roles

Access is controlled via a bitmask on the `User` model:

| Role | Capabilities |
|---|---|
| `member` | View voyages, register for sailings, manage own profile |
| `office_staff` | Full member management, create/edit/delete voyages |
| `crewing_operator` | Manage crew for voyages, view manifests |
| `maintenance` | Maintenance task management |

## Running Tests

```bash
bin/rails test            # All unit and integration tests
bin/rails test:system     # Capybara/Selenium system tests (headless Chrome)
bin/rails test test/models/user_test.rb        # Single file
bin/rails test test/models/user_test.rb:42     # Single test by line
```

## Deployment using Kamal
Kamal is used for deploying the application to a Docker-based server. This requires docker to be installed on your local machine.  Also kamal requires an ssh key to be set up on the server, i.e. passwordless login.
