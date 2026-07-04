# Preview all emails at http://localhost:3000/rails/mailers/membership_mailer
class MembershipMailerPreview < ActionMailer::Preview
  # Preview at http://localhost:3000/rails/mailers/membership_mailer/new_application
  def new_application
    MembershipMailer.new_application(User.take)
  end

  # Preview at http://localhost:3000/rails/mailers/membership_mailer/application_received
  def application_received
    MembershipMailer.application_received(User.take)
  end
end
