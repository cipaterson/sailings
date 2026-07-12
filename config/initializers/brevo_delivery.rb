require "my_mailer/brevo_delivery_method"

ActionMailer::Base.add_delivery_method(:brevo, MyMailer::BrevoDeliveryMethod)
ActionMailer::Base.brevo_settings = { api_key: Rails.application.credentials.dig(:brevo, :api_key) }
ActionMailer::Base.delivery_method = :brevo if Rails.env.production?
