require "test_helper"

class AppConfigTest < ActiveSupport::TestCase
  test "office_email returns the in-code default" do
    assert_equal AppConfig::DEFAULT_OFFICE_EMAIL, AppConfig.office_email
  end

  test "office_email honours the OFFICE_EMAIL env override" do
    original = ENV["OFFICE_EMAIL"]
    ENV["OFFICE_EMAIL"] = "custom-office@example.com"
    assert_equal "custom-office@example.com", AppConfig.office_email
  ensure
    ENV["OFFICE_EMAIL"] = original
  end

  test "charter_colors covers every charter state with a hex color" do
    colors = AppConfig.charter_colors
    assert_equal %w[tbc confirmed outstanding paid].sort, colors.keys.sort
    assert colors.values.all? { |c| c.match?(/\A#[0-9a-fA-F]{3,8}\z/) }
  end
end
