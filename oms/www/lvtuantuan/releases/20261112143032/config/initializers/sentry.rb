# frozen_string_literal: true

Sentry.init do |config|
  # options: https://docs.sentry.io/platforms/ruby/guides/rails/configuration/options/
  config.dsn = Rails.application.credentials.dig(Rails.env.to_sym, :sentry_dsn)
  config.breadcrumbs_logger = [:active_support_logger]
  config.enabled_environments = %w[production staging]
  config.traces_sample_rate = 0
end
