# frozen_string_literal: true

module WMSLib
  HOSTS = Rails.application.credentials.dig(Rails.env.to_sym, :wms, :hosts) || []
  SIGN_KEY = Rails.application.credentials.dig(Rails.env.to_sym, :wms, :key)

  @@logger = Logger.new(Rails.root.join("log", "wms.log"))

  def self.sync_products!(products)
    @@logger.info("sync_products: #{ products }")
    timestamp = Time.now.to_i
    HOSTS.each do |host|
      RestClient.post(
        "#{host}/api/oms/products/sync?sign=#{sign(timestamp)}&timestamp=#{timestamp}",
        { products: products }.to_json,
        {content_type: :json, accept: :json}
      )
    end
  end

  def self.sign(timestamp)
    Digest::MD5.hexdigest("#{SIGN_KEY}#{timestamp}")
  end
end
