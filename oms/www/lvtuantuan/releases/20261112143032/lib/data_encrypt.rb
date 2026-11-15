# frozen_string_literal: true

class DataEncrypt
  KEY = Rails.application.credentials.dig(Rails.env.to_sym, :aes_key)

  def self.aes128_encrypt(data)
    return nil if data.blank?
    cipher = OpenSSL::Cipher::AES.new(128, :ECB)
    cipher.encrypt
    cipher.key = KEY
    Base64.strict_encode64(cipher.update(data.to_s) << cipher.final)
  end

  def self.aes128_decrypt(data)
    cipher = OpenSSL::Cipher::AES.new(128, :ECB)
    cipher.decrypt
    cipher.key = KEY
    cipher.update(Base64.decode64(data)) << cipher.final
  end
end
