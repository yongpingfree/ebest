# frozen_string_literal: true

module TencentMap
  class Api
    include HTTParty
    HTTP_ERRORS = [
      EOFError,
      Errno::ECONNRESET,
      Errno::EINVAL,
      Net::HTTPBadResponse,
      Net::HTTPHeaderSyntaxError,
      Net::ProtocolError,
      Timeout::Error
    ]
    HTTPARTY_TIMEOUT = 15
    RETRY_TIMES = 3

    base_uri "https://apis.map.qq.com/ws"
    TENCENT_MAP_CONFIG = Rails.application.credentials.dig(Rails.env.to_sym, :tencent_map)

    @@logger = ::Logger.new("./log/tencent_map_api.log")

    def self.get_au_suburb_by_location(latitude, longitude)
      tries = RETRY_TIMES
      path = "/geocoder/v1?location=#{latitude},#{longitude}&language=en&key=#{TENCENT_MAP_CONFIG[:key]}"
      response = get(path, timeout: HTTPARTY_TIMEOUT, verify: false)
      if response["status"] == 0
        response["result"]
      else
        @@logger.debug("response: #{response}")
        {}
      end
    rescue Net::OpenTimeout, Net::ReadTimeout => _
      if (tries -= 1) > 0
        retry
      else
        @@logger.debug("请求超时，请重试")
        {}
      end
    end

    def self.suggestion_addresses(keyword)
      tries = RETRY_TIMES
      path = "/place/v1/suggestion?key=#{TENCENT_MAP_CONFIG[:key]}&keyword=#{URI.encode(keyword)} Australia&oversea=1&language=en"
      response = get(path, timeout: HTTPARTY_TIMEOUT, verify: false)
      if response["status"] == 0
        format_address(response["data"])
      else
        @@logger.debug("response: #{response}")
        []
      end
    rescue Net::OpenTimeout, Net::ReadTimeout, OpenSSL::SSL::SSLError => _
      if (tries -= 1) > 0
        retry
      else
        @@logger.debug("请求超时，请重试")
        []
      end
    end

    private
    def self.format_address(data)
      data.map do |address|
        address_arr = address["address"]&.split("\n") || []
        country = address_arr.last
        next if country != "Australia"
        arr = address_arr[-2]&.split
        postal_code, province_name, city_name =
          if arr.present?
            # 判断postal_code是否存在
            if arr.last.to_i.to_s == arr.last
              postal_code = arr.last
              province_name = arr[-2]
              city_name = arr[0..-3]&.join(" ")
            else
              postal_code = nil
              province_name = arr.last
              city_name = arr[0..-2]&.join(" ")
            end

            # 存在数据没有州
            if province_name.length > 3
              city_name = "#{city_name} #{province_name}"
              province_name = nil
            end

            [postal_code, province_name, city_name]
          else
            [nil, nil, nil]
          end
        street_first_string = address["title"]&.split&.first
        street_number = street_first_string.to_i.to_s == street_first_string ? street_first_string : nil

        {
          address: "#{address["title"]}, #{address_arr.join(", ")}",
          country: country,
          province_name: province_name,
          postal_code: postal_code,
          city_name: city_name,
          detail_info: address["title"],
          street_number: street_number,
          latitude: address["location"]["lat"],
          longitude: address["location"]["lng"],
        }
      end.compact
    end
  end
end
