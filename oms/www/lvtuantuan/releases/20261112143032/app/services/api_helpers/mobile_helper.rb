# frozen_string_literal: true

module ApiHelpers
  module MobileHelper
    def check_phone_number!(number)
      number.gsub!(/[\s\-_*+]/, "")
      # 小程序成为会员传过来的号码前面为6161，所以要把前4位替换成61
      # 小程序成为会员传过来的号码前面多了6104，所以要把前4位替换成614
      number.gsub!(/^.{4}/, "61") if number.start_with?("6161")
      number.gsub!(/^.{4}/, "614") if number.start_with?("6104")
      response_error(I18n.t("error.common.missing_params")) if number.blank?
      response_error(I18n.t("error.mobile.invalid_format")) unless Phony.plausible?(number)
      response_error(I18n.t("error.order.fraud_account")) if MagicBean::MobileBlacklist.activated?(number, :order_disabled)
    end

    def check_verification_code!(phone_number, verification_code, event)
      response_error(I18n.t("error.common.missing_params")) if verification_code.blank?
      vc = MagicBean::VerificationCode.public_send("build_#{event}_object", phone_number)
      response_error(I18n.t("error.mobile.invalid_code")) unless vc.verify(verification_code)
      vc.code = nil
    end

    def shopline_check_phone_number!(number)
      response_shopline_error(I18n.t("error.common.missing_params", locale: :en)) if number.blank?
      response_shopline_error(I18n.t("error.mobile.invalid_format", locale: :en)) unless Phony.plausible?(number)
    end

    def shopline_check_verification_code!(phone_number, verification_code, event)
      tmp_number = shopline_format_phone(phone_number)
      response_shopline_error(I18n.t("error.common.missing_params", locale: :en)) if verification_code.blank?
      vc = MagicBean::VerificationCode.public_send("build_#{event}_object", tmp_number)
      response_shopline_error(I18n.t("error.mobile.invalid_code", locale: :en)) unless vc.verify(verification_code)
      vc.code = nil
    end

    def shopline_format_phone(number)
      tmp_number = number.gsub(/[\s\-_*+]/, "")
      tmp_number.gsub!(/^.{2}/, "") if tmp_number.start_with?("00")
      tmp_number.gsub!(/^.{4}/, "614") if tmp_number.start_with?("6104")
      tmp_number
    end
  end
end
