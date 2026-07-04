require "test_helper"

class MembershipMailerTest < ActionMailer::TestCase
  setup do
    @user = User.create!(
      email_address: "applicant@example.com",
      password: "ValidPass1!",
      first_name: "Ann", last_name: "Applicant",
      occupation: "Sailor",
      contact_attributes: { mobile: "0400000000", city: "Sydney" },
      next_of_kin_attributes: { full_name: "Kin Person", mobile: "0411111111" }
    )
  end

  test "new_application goes to the configured office address with full details" do
    mail = MembershipMailer.new_application(@user)

    assert_equal [ AppConfig.office_email ], mail.to
    assert_equal "New membership application from Ann Applicant", mail.subject

    body = mail.body.encoded
    assert_includes body, "applicant@example.com"
    assert_includes body, "0400000000"
    assert_includes body, "Kin Person"
    assert_includes body, "0411111111"
  end

  test "application_received goes to the applicant" do
    mail = MembershipMailer.application_received(@user)

    assert_equal [ @user.email_address ], mail.to
    assert_includes mail.subject, "received"
    assert_includes mail.body.encoded, "Ann Applicant"
  end
end
