# frozen_string_literal: true

module GooglePlaces
  class Client
    @@logger = ::Logger.new("./log/google_places_api.log")
    MAX_REQUEST_GOOGLE_NEARBY_COUNT = 5
    BASIC_PATH = "https://maps.googleapis.com/maps/api/place/nearbysearch"
    def self.client
      @client ||= GooglePlaces::Client.new(app_key)
    end

    def self.logger
      @@logger
    end

    def self.app_key
      Rails.application.credentials.dig(Rails.env.to_sym, :google_places, :app_key)
    end

    def self.nearby(location, fields)
      path = "#{BASIC_PATH}/json?location=#{location}&rankby=distance&key=#{app_key}&fields=#{fields}"

      @@logger.info("request: method: get, url: #{BASIC_PATH}, location: #{location}")
      response = RestClient.get(path)
      response = JSON.parse(response) if response
      if response["status"].eql?("OK")
        results = response.dig("results")
        @@logger.info("response: #{results[0]}")
      else
        @@logger.error("response errors: #{response}")
        results = []
      end
      results
    rescue => e
      @@logger.error("exception message: #{e}")
      []
    end
  end
end
