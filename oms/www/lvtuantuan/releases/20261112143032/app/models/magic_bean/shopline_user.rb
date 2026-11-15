# frozen_string_literal: true

class MagicBean::ShoplineUser < ApplicationRecord
  has_secure_password

  validates_length_of :password, within: 6..18, allow_blank: true
  validates :email, presence: true, uniqueness: true

  def generate_reset_password_token
    loop do
      self.reset_password_token = SecureRandom.uuid
      break unless self.class.exists?(reset_password_token: reset_password_token)
    end
  end

  def generate_reset_email_token
    loop do
      self.reset_email_token = SecureRandom.uuid
      break unless self.class.exists?(reset_email_token: reset_email_token)
    end
  end

  def generate_reset_phone_token
    loop do
      self.reset_phone_token = SecureRandom.uuid
      break unless self.class.exists?(reset_phone_token: reset_phone_token)
    end
  end

  def update_shopline_user_email(old_email)
    update_shopline_user_id(old_email)
    response = Shopline::Api.update_customer_email(shopline_user_id, { "email": email })
    raise response["errors"] if response["errors"].present?
  end

  def update_shopline_user_phone
    update_shopline_user_id(email)
    response = Shopline::Api.update_customer_email(shopline_user_id, { "phone": phone })
    raise response["errors"] if response["errors"].present?
  end

  private
  def update_shopline_user_id(old_email)
    if shopline_user_id.blank?
      customer = Shopline::Api.search_customers("email:#{old_email}")["customers"].first
      update!(shopline_user_id: customer["id"], addresses: customer["addresses"], phone: customer["phone"])
    end
  end
end
