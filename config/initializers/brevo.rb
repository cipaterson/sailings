require "action_mailer/brevo_delivery_method"

ActionMailer::Base.add_delivery_method(
  :brevo,
  ActionMailer::BrevoDeliveryMethod
)
