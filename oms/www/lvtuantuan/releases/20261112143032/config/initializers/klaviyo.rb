# frozen_string_literal: true

# Setup authorization
KlaviyoAPI.configure do |config|
  config.api_key["Klaviyo-API-Key"] = "Klaviyo-API-Key #{Rails.application.credentials[:klaviyo_api_key]}"
  #config.max_retries = 5 # optional
  #config.max_delay = 60 # optional
end
