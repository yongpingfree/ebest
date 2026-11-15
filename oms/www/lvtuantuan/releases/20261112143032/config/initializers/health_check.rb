# frozen_string_literal: true

redis_config = Rails.application.credentials.dig(Rails.env.to_sym, :redis)
redis_server = redis_config[:redis_server]
redis_port = redis_config[:redis_port]
redis_db_num = redis_config[:redis_db_num]

HealthCheck.setup do |config|

  # uri prefix (no leading slash)
  config.uri = "health_check"

  # Text output upon success
  config.success = "success"

  # Timeout in seconds used when checking smtp server
  config.smtp_timeout = 30.0

  # http status code used when plain text error message is output
  # Set to 200 if you want your want to distinguish between partial (text does not include success) and
  # total failure of rails application (http status of 500 etc)

  config.http_status_for_error_text = 500

  # You can customize which checks happen on a standard health check, eg to set an explicit list use:
  config.standard_checks = ["database", "migrations"]

  # You can set what tests are run with the 'full' or 'all' parameter
  config.full_checks = ["database", "migrations", "cache", "redis", "sidekiq-redis"]

  # max-age of response in seconds
  # cache-control is public when max_age > 1 and basic_auth_username is not set
  # You can force private without authentication for longer max_age by
  # setting basic_auth_username but not basic_auth_password
  config.max_age = 1

  # When redis url is non-standard
  config.redis_url = "redis://#{redis_server}:#{redis_port}/#{redis_db_num}"
end
