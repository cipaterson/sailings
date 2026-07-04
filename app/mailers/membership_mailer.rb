class MembershipMailer < ApplicationMailer
  # Notifies the office that a new membership application has been submitted,
  # including all the details the applicant provided.
  def new_application(user)
    @user = user
    @contact = user.contact
    @next_of_kin = user.next_of_kin

    mail(
      to: AppConfig.office_email,
      subject: "New membership application from #{user.full_name}"
    )
  end

  # Confirms to the applicant that their application was received and is pending.
  def application_received(user)
    @user = user

    mail(
      to: user.email_address,
      subject: "We've received your membership application"
    )
  end
end
