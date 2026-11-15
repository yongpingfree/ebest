# frozen_string_literal: true

require "jwt"

class JsonWebToken
  # Encodes and signs JWT Payload with expiration
  def self.encode(payload)
    payload.reverse_merge!(meta)
    JWT.encode(payload, Rails.application.credentials.dig(Rails.env.to_sym, :jwt_secret))
  end

  # Decodes the JWT with the signed secret
  def self.decode(token)
    JWT.decode(token, Rails.application.credentials.dig(Rails.env.to_sym, :jwt_secret))
  end

  # Validates the payload hash for expiration and meta claims
  def self.valid_payload(payload)
    if expired(payload) || payload["issu"] != meta[:issu]
      return false
    else
      return true
    end
  end

  # Default options to be encoded in the token
  def self.meta
    {
      issu: "ecommerce_backend_base",
      iat: Time.current,
      expired_at: 30.days.from_now.to_i,
    }
  end

  # Validates if the token is expired by exp parameter
  def self.expired(payload)
    expired_at = Time.at(payload["expired_at"])
    if Rails.env.test?
      expired_at < Time.current
    elsif Rails.env.staging?
      expired_at < Time.current || expired_at < "2020-10-30 18:10".in_time_zone
    else
      expired_at < Time.current || expired_at < "2020-10-30 23:30".in_time_zone
    end
  end
end
