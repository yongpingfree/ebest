# frozen_string_literal: true

Rails.application.config.action_mailer.delivery_method = :smtp
Rails.application.config.action_mailer.smtp_settings = {
  address:              Rails.application.credentials[Rails.env.to_sym][:smtp][:address],
  port:                 465,
  user_name:            Rails.application.credentials[Rails.env.to_sym][:smtp][:user_name],
  password:             Rails.application.credentials[Rails.env.to_sym][:smtp][:password],
  authentication:       "plain",
  enable_starttls_auto: true,
  tls: true
}
