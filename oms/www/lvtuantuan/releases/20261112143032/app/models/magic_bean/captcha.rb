# frozen_string_literal: true

require "base64"
require "securerandom"
require "rucaptcha"

module MagicBean
  class Captcha
    EXPIRATION = 5.minutes
    CACHE_KEY_PREFIX = "captcha"

    attr_reader :key, :mobile, :event, :image_data

    def initialize(key, mobile: nil, event: nil, image_data: nil)
      @key = key.to_s
      @mobile = mobile.to_s
      @event = event.to_s
      @image_data = image_data
    end

    def self.generate(mobile:, event:)
      key = SecureRandom.hex(16)
      code, image_data = RuCaptcha.generate
      captcha = new(key, mobile: mobile, event: event, image_data: image_data)
      captcha.write(code)
      captcha
    end

    def self.verify(key, code, mobile:, event:)
      new(key, mobile: mobile, event: event).verify(code)
    end

    def verify(input_code)
      cached_value = Rails.cache.read(cache_key) || {}
      Rails.cache.delete(cache_key) if cached_value.present?

      cached_code = cached_value[:code].to_s
      return false if cached_code.blank? || input_code.blank?
      return false unless secure_equal?(cached_value[:mobile], mobile)
      return false unless secure_equal?(cached_value[:event], event)

      secure_equal?(cached_code.downcase, input_code.to_s.strip.downcase)
    end

    def image_data_uri
      "data:image/gif;base64,#{Base64.strict_encode64(image_data)}"
    end

    def write(code)
      Rails.cache.write(
        cache_key,
        { code: code.to_s, mobile: mobile, event: event },
        expires_in: EXPIRATION
      )
    end

    private

    def cache_key
      "#{CACHE_KEY_PREFIX}:#{key}"
    end

    def secure_equal?(left, right)
      left = left.to_s
      right = right.to_s
      return false if left.blank? || right.blank? || left.bytesize != right.bytesize

      ActiveSupport::SecurityUtils.secure_compare(left, right)
    end
  end
end
