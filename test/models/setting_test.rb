require "test_helper"

class SettingTest < ActiveSupport::TestCase
  test "write then read returns the stored value" do
    Setting.write("office_email", "hello@example.com")
    assert_equal "hello@example.com", Setting["office_email"]
  end

  test "write stores structured (hash) values" do
    Setting.write("charter_colors", { "tbc" => "#111111" })
    assert_equal({ "tbc" => "#111111" }, Setting["charter_colors"])
  end

  test "a second write updates the value and refreshes the cache" do
    Setting.write("office_email", "first@example.com")
    assert_equal "first@example.com", Setting["office_email"]

    Setting.write("office_email", "second@example.com")
    assert_equal "second@example.com", Setting["office_email"]
  end

  test "unknown keys read as nil" do
    assert_nil Setting["does_not_exist"]
  end

  test "key is required and unique" do
    Setting.write("dup", "a")
    duplicate = Setting.new(key: "dup", value: "b")
    assert_not duplicate.valid?
  end
end
