require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # No system Chrome is installed; Selenium Manager auto-downloads "Chrome for
  # Testing" into ~/.cache/selenium. Rails' driver preloading keeps only the
  # chromedriver path and drops the resolved browser path, so chromedriver fails
  # with "cannot find Chrome binary". Re-attach the browser binary explicitly.
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 900 ] do |options|
    options.binary = Selenium::WebDriver::SeleniumManager.binary_paths("--browser", "chrome")["browser_path"]
  end

  def sign_in_as(user, password: "password")
    visit new_session_path
    fill_in "email_address", with: user.email_address
    fill_in "password", with: password
    click_on "Sign in"
  end
end
