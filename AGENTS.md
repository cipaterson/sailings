# AGENTS.md

This file provides guidance to agentic coding agents working in this repository.

## Overview

`sailings` is a Rails 8.1 application for managing sailing voyages. It uses SQLite, Hotwire (Turbo + Stimulus), importmap, Propshaft, Solid Queue, Solid Cache, and Solid Cable. Ruby version: 3.4.2.

## Build/Lint/Test Commands

```bash
# Start development server
bin/rails server

# Run all tests
bin/rails test

# Run a single test file
bin/rails test test/models/user_test.rb

# Run a single test by line number
bin/rails test test/models/user_test.rb:42

# Run tests matching a pattern
bin/rails test --name="/password/"

# Run system tests (browser-based with Capybara + Selenium)
bin/rails test:system

# Lint with RuboCop
bin/rubocop

# Auto-correct RuboCop violations
bin/rubocop -A

# Security audit
bin/brakeman
bundle exec bundler-audit

# Database operations
bin/rails db:create db:migrate
bin/rails db:migrate
bin/rails db:migrate:status

# Rails console
bin/rails console
```

## Code Style

### General

- Uses `rubocop-rails-omakase` (Rails' opinionated style guide)
- Config is in `.rubocop.yml`
- Run `bin/rubocop` before committing
- Prefer `bundle exec` for gem commands

### Ruby Conventions

```ruby
# Constants are SCREAMING_SNAKE_CASE and frozen
MEMBERSHIP_TYPES = %w[Life Family Individual Junior].freeze

# Use symbols for hash keys when possible
{ key: "value" }

# Use single quotes for strings unless interpolation needed
"string #{with_interpolation}"

# Use %i for symbol arrays, %w for string arrays
ROLES = %w[member office_staff crewing_operator maintenance].freeze

# Use `and`/`or` sparingly; prefer `&&`/`||`
# Use trailing `if/unless` for guard clauses

# Prefer method shorthand for simple accessors
def departs_date = departs_at&.to_date
```

### Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Models | Singular, PascalCase | `User`, `Sailing` |
| Controllers | Plural, PascalCase | `UsersController` |
| Tables | Plural, snake_case | `sailing_participants` |
| Variables | snake_case | `@sailing_participants` |
| Methods | snake_case | `def full_name` |
| Scopes | snake_case | `scope :with_role, ->(role) { ... }` |
| Query params | snake_case | `from_date`, `to_date` |
| CSS classes | kebab-case | `tab-labels`, `tab-panel` |
| JS classes | PascalCase | `PasswordStrengthController` |

### File Organization

```
app/
  controllers/     # One controller per resource
  models/          # One model per table
  views/           # Mirrors controllers: sailings/, users/, etc.
  jobs/            # Background job classes
  mailers/         # Mailer classes and views
  javascript/
    controllers/   # Stimulus controllers: name_controller.js
  assets/
    stylesheets/   # application.css (plain CSS, no preprocessor)
config/
  importmap.rb     # Pin JS packages here
db/
  migrate/         # Timestamped migrations
test/
  models/          # Unit tests for models
  controllers/    # Integration tests for controllers
  fixtures/        # YAML fixtures
  test_helpers/    # Custom test helpers
```

### Model Patterns

```ruby
class User < ApplicationRecord
  # Define constants for enums/stati at top
  MEMBERSHIP_TYPES = %w[Life Family Individual Junior].freeze

  # Associations
  has_many :sessions, dependent: :destroy
  has_many :sailings, through: :sailing_participants

  # Normalizations
  normalizes :email_address, with: ->(e) { e.strip.downcase }

  # Validations
  validates :membership_type, inclusion: { in: MEMBERSHIP_TYPES }, allow_blank: true

  # Scopes (public methods)
  scope :with_role, ->(role) { where(...) }

  # Public methods
  def full_name
    "#{first_name} #{last_name}".strip.presence || email_address
  end

  # Private methods at bottom
  private

  def password_complexity
    # ...
  end
end
```

### Controller Patterns

```ruby
class SailingsController < ApplicationController
  # Use only/except to limit before_actions
  before_action :set_sailing, only: %i[show edit update destroy]

  # Strong parameters in private method
  def sailing_params
    params.require(:sailing).permit(:purpose, :status, :departs_date)
  end

  # Use Turbo streams for AJAX responses
  def update
    if @sailing.update(sailing_params)
      redirect_to @sailing, notice: "Sailing was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end
end
```

### Migration Patterns

```ruby
class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email_address, null: false
      t.timestamps
    end
    add_index :users, :email_address, unique: true
  end
end
```

### Test Patterns

```ruby
require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "with_role scope returns users with that role" do
    user = users(:one)
    user.update!(roles: [ "maintenance" ])
    assert_includes User.with_role("maintenance"), user
  end
end

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = User.take }

  test "create with valid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "password" }
    assert_redirected_to root_path
    assert cookies[:session_id]
  end
end
```

### JavaScript (Stimulus) Patterns

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["password", "confirmation"]
  static values  = { optional: { type: Boolean, default: false } }

  connect() {
    // Initialization
  }

  check() {
    // Event handler
  }
}
```

### View Patterns

```erb
<%= form_with model: sailing do |f| %>
  <% if sailing.errors.any? %>
    <div>
      <% sailing.errors.full_messages.each do |msg| %>
        <p><%= msg %></p>
      <% end %>
    </div>
  <% end %>

  <div>
    <%= f.label :purpose %>
    <%= f.text_field :purpose %>
  </div>

  <%= f.submit %>
<% end %>
```

### Error Handling

- Use `rescue` for parameter parsing: `Date.parse(params[:date]) rescue nil`
- Return appropriate HTTP status codes: `:unprocessable_entity` for validation errors
- Use `redirect_to` with `notice:` or `alert:` for user-facing messages
- Use `find!` (bang) when find failure should raise
- Use `find_by` (no bang) when nil is acceptable

### Authentication

- Uses cookie-based sessions with `Session` model
- Current user accessible via `Current.user`
- Use `require_role!` helper for authorization:
  ```ruby
  require_role!("office_staff")
  require_role!("office_staff", "crewing_operator")
  ```
- Use `allow_unauthenticated_access` for public controller actions

### Background Jobs

- Jobs go in `app/jobs/` and extend `ApplicationJob`
- Solid Queue runs inside Puma via `SOLID_QUEUE_IN_PUMA`
- Use `deliver_later` for mailers in jobs

### Database

- SQLite in all environments (development, test, production)
- Four databases in production: primary, cache, queue, cable
- All stored in `storage/` in production
