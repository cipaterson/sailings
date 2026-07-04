require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  test "new is reachable without authentication" do
    get new_registration_path
    assert_response :success
  end

  test "successful sign-up emails the office and the applicant" do
    assert_enqueued_emails 2 do
      post registration_path, params: { user: {
        email_address: "notify@example.com",
        password: "ValidPass1!",
        password_confirmation: "ValidPass1!",
        first_name: "Ann", last_name: "Applicant",
        contact_attributes: { mobile: "0400000000" },
        next_of_kin_attributes: { full_name: "Kin Person" }
      } }
    end
  end

  test "invalid sign-up sends no email" do
    assert_no_enqueued_emails do
      post registration_path, params: { user: { email_address: "bad@example.com", password: "weak" } }
    end
  end

  test "sign-up creates a pending account without starting a session" do
    assert_difference "User.count", 1 do
      post registration_path, params: { user: {
        email_address: "applicant@example.com",
        password: "ValidPass1!",
        password_confirmation: "ValidPass1!",
        first_name: "Ann", last_name: "Applicant"
      } }
    end

    user = User.find_by(email_address: "applicant@example.com")
    assert_not user.approved?, "new sign-up must be pending"
    assert_equal [ "member" ], user.roles, "default member role is assigned"
    assert_nil cookies[:session_id].presence, "no session is started on sign-up"
    assert_redirected_to new_session_path
  end

  test "sign-up ignores privileged params" do
    post registration_path, params: { user: {
      email_address: "sneaky@example.com",
      password: "ValidPass1!",
      password_confirmation: "ValidPass1!",
      roles: [ "office_staff" ],
      fees_paid: "2020-01-01",
      approved_at: Time.current
    } }

    user = User.find_by(email_address: "sneaky@example.com")
    assert_equal [ "member" ], user.roles, "roles cannot be self-assigned"
    assert_nil user.fees_paid, "fees cannot be self-assigned"
    assert_nil user.approved_at, "approval cannot be self-assigned"
  end

  test "sign-up with nested contact and next of kin" do
    assert_difference "User.count", 1 do
      post registration_path, params: { user: {
        email_address: "nested@example.com",
        password: "ValidPass1!",
        password_confirmation: "ValidPass1!",
        contact_attributes: { mobile: "0400000000", city: "Sydney" },
        next_of_kin_attributes: { full_name: "Kin Person", mobile: "0411111111" }
      } }
    end

    user = User.find_by(email_address: "nested@example.com")
    assert_equal "0400000000", user.contact.mobile
    assert_equal "Kin Person", user.next_of_kin.full_name
  end

  test "invalid sign-up re-renders the form" do
    assert_no_difference "User.count" do
      post registration_path, params: { user: {
        email_address: "weak@example.com", password: "weak"
      } }
    end
    assert_response :unprocessable_entity
  end
end
