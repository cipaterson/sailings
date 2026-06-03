class ApplicationMailer < ActionMailer::Base
  self.delivery_method = :brevo
  default from: "no-reply@sailings.firstsoftware.cc"
  layout "mailer"
end
