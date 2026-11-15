# frozen_string_literal: true

module ApiHelpers
  module ShoplineHelper
     # mutipass跳转路径https://ebest-test.myshopline.com/api/user/account/login/multipass/:token
     def generate_multipass_token(user)
      plaintext = {
        "email": user.email,
        "created_at": Time.current.strftime("%Y-%m-%dT%H:%M:%S%:z"),
      }.to_json

      secret = Shopline::Api::SHOPLINE_SETTING[:multipass_key]

      # SHA-256 hash
      encoded_hash = OpenSSL::Digest.digest('SHA256', secret)
      encrypted_key = encoded_hash[0, 16]
      sign_key = encoded_hash[16, 16]
    
      # iv
      iv = OpenSSL::Random.random_bytes(16)
      encrypted_key_spec = OpenSSL::Cipher.new('AES-128-CBC').encrypt
      encrypted_key_spec.key = encrypted_key
      encrypted_key_spec.iv = iv
    
      # encrypt byte array
      encrypted = encrypted_key_spec.update(plaintext) + encrypted_key_spec.final
    
      iv_encrypted_byte = iv + encrypted
    
      sign_byte = OpenSSL::HMAC.digest('sha256', sign_key, iv_encrypted_byte)
    
      token_bytes = iv_encrypted_byte + sign_byte
      
      token = Base64.urlsafe_encode64(token_bytes).gsub("=", "")
      
      token
    end
  end
end
