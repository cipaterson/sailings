require "application_system_test_case"

class AuthenticationTest < ApplicationSystemTestCase
  test "user can sign in with valid credentials" do
    sign_in_as users(:member)
    assert_current_path root_path
  end

  test "sign in with wrong password shows error" do
    sign_in_as users(:member), password: "wrongpassword"
    assert_current_path new_session_path, ignore_query: true
  end

  test "unauthenticated user is redirected to sign in" do
    visit sailings_path
    assert_current_path new_session_path
  end

  test "user can sign out" do
    sign_in_as users(:member)
    click_on "Logout"
    assert_current_path new_session_path
  end
end
