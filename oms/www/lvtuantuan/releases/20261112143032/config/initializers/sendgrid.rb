# frozen_string_literal: true
require "sendgrid-ruby"

sendgrid_config = Rails.application.credentials.dig(Rails.env.to_sym, :sendgrid)

SendGridApi = SendGrid::API.new(api_key: sendgrid_config[:api_key])
