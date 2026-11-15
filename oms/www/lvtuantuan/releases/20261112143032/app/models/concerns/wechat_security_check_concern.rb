# frozen_string_literal: true

module WechatSecurityCheckConcern
  extend ActiveSupport::Concern

  included do
    validate :msg_sec_check, if: :should_check_text?
    validate :img_sec_check, if: :should_check_img?
  end

  def msg_sec_check
    return true if check_text.blank?
    msg_check = ::Wechat::SecurityMsgCheck.new(check_text)
    unless msg_check.valid?
      self.errors.add(:base, msg_check.instance_variable_get(:@error))
      return false
    end
  end

  def img_sec_check
    error_messages = check_imgs.map do |url|
      next if url.blank?
      if URI.parse(url).host.in?(Validators::ResourceUrl::HOST_ARRAY)
        img_check = ::Wechat::SecurityImgCheck.new(url)
        unless img_check.valid?
          img_check.instance_variable_get(:@error)
        end
      else
        "无效链接"
      end
    end.compact
    if error_messages.present?
      self.errors.add(:base, error_messages.first)
      return false
    end
  end

  def msg_sec_check_attributes
    self.class::MSG_SEC_CHECK_ATTRIBUTES rescue []
  end

  def img_sec_check_attributes
    self.class::IMG_SEC_CHECK_ATTRIBUTES rescue []
  end

  def check_text
    check_msg_columns.map do |column|
      public_send(column)
    end.join(",")
  end

  def check_imgs
    check_img_columns.map do |column|
      public_send(column)
    end.flatten
  end

  def changes_keys
    changes_to_save.transform_values(&:first).keys
  end

  def check_img_columns
    changes_keys & img_sec_check_attributes
  end

  def check_msg_columns
    changes_keys & msg_sec_check_attributes
  end

  def should_check_text?
    check_msg_columns.any?
  end

  def should_check_img?
    check_img_columns.any?
  end
end
