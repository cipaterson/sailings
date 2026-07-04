require "test_helper"

class SettingsControllerTest < ActionDispatch::IntegrationTest
  test "unauthenticated user cannot access settings" do
    get edit_settings_path
    assert_redirected_to new_session_path
  end

  test "non-office-staff cannot access settings" do
    sign_in_as users(:member)
    get edit_settings_path
    assert_redirected_to root_path
  end

  test "office_staff can view the settings form" do
    sign_in_as users(:office_staff)
    get edit_settings_path
    assert_response :success
  end

  test "office_staff can update settings" do
    sign_in_as users(:office_staff)
    patch settings_path, params: {
      office_email: "newoffice@example.com",
      charter_colors: { "tbc" => "#111111", "confirmed" => "#222222",
                        "outstanding" => "#333333", "paid" => "#444444" }
    }
    assert_redirected_to edit_settings_path
    assert_equal "newoffice@example.com", AppConfig.office_email
    assert_equal "#111111", AppConfig.charter_colors["tbc"]
  end

  test "invalid email is rejected and nothing is persisted" do
    sign_in_as users(:office_staff)
    patch settings_path, params: {
      office_email: "not-an-email",
      charter_colors: AppConfig::DEFAULT_CHARTER_COLORS
    }
    assert_response :unprocessable_entity
    assert_nil Setting["office_email"]
  end

  test "invalid color is rejected and nothing is persisted" do
    sign_in_as users(:office_staff)
    patch settings_path, params: {
      office_email: "ok@example.com",
      charter_colors: { "tbc" => "#111111", "confirmed" => "#222222",
                        "outstanding" => "#333333", "paid" => "red; } body {}" }
    }
    assert_response :unprocessable_entity
    assert_nil Setting["office_email"]
    assert_nil Setting["charter_colors"]
  end
end
