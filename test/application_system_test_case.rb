require "test_helper"
require "minitest/retry"

# Headless Chrome runs the whole suite in a single process against a Puma server
# in a background thread. Under that load, async transitions (post-login
# redirect + render, Turbo navigations, TomSelect dropdown close) can take
# longer than Capybara's 2s default, causing intermittent "element not found"
# flakes. Give them more slack.
Capybara.default_max_wait_time = 5

# Auto-retry flaky system tests. This file is only loaded for system-test runs,
# so unit/integration tests (run via `bin/rails test`) are never retried and
# real failures there still surface immediately.
Minitest::Retry.use!(retry_count: 2, verbose: true, io: $stdout)

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # No system Chrome is installed; Selenium Manager auto-downloads "Chrome for
  # Testing" into ~/.cache/selenium. Rails' driver preloading keeps only the
  # chromedriver path and drops the resolved browser path, so chromedriver fails
  # with "cannot find Chrome binary". Re-attach the browser binary explicitly.
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 900 ] do |options|
    options.binary = Selenium::WebDriver::SeleniumManager.binary_paths("--browser", "chrome")["browser_path"]
  end

  def sign_in_as(user, password: "password", expect_success: true)
    visit new_session_path
    submit_login(user, password)
    return unless expect_success

    # Successful logins redirect to the user's preferred home, which varies per
    # user, so synchronize on the always-present Logout link (in the nav on every
    # authenticated layout) rather than a specific landing page. Under
    # headless-Chrome load the first submit occasionally doesn't take (field/click
    # race), leaving us on the sign-in page — retry once before asserting.
    unless has_selector?("a", text: "Logout")
      submit_login(user, password) if has_field?("email_address")
      assert_selector "a", text: "Logout"
    end
  end

  private

  def submit_login(user, password)
    fill_in "email_address", with: user.email_address
    fill_in "password", with: password
    click_on "Sign in"
  end
end
