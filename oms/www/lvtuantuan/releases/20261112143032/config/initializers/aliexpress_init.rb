# frozen_string_literal: true

require "iop_api_client"

ae_config = Rails.application.credentials.dig(Rails.env.to_sym, :aliexpress)

AEClient = IopApiClient::Client.new("https://api-sg.aliexpress.com/rest", ae_config[:app_key].to_s, ae_config[:app_secret])

AETopClient = IopApiClient::Client.new("https://api-sg.aliexpress.com/sync?method=", ae_config[:app_key].to_s, ae_config[:app_secret])

AEOverseaClient = IopApiClient::Client.new("https://api-sg.aliexpress.com/rest", ae_config[:oversea_app_key].to_s, ae_config[:oversea_app_secret])

AEOverseaTopClient = IopApiClient::Client.new("https://api-sg.aliexpress.com/sync?method=", ae_config[:oversea_app_key].to_s, ae_config[:oversea_app_secret])
