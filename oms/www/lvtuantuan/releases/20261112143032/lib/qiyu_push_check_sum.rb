# frozen_string_literal: true

class QiyuPushCheckSum
  ANDROID_APP_SECRET = Rails.application.credentials.dig(Rails.env.to_sym, :qiyukf, :android_app_secret)

  class << self
    def verify(params)
      nonce = params[:nonce]
      time = params[:time]
      checksum = params[:checksum]

      return false if [nonce, time, checksum].compact.size != 3

      checksum == calculate_checksum(nonce, time)
    end

    def calculate_checksum(nonce, time)
      Digest::SHA1.hexdigest(ANDROID_APP_SECRET + nonce + time.to_s).downcase
    end
  end
end
