# frozen_string_literal: true

module ApiHelpers
  module EmailHelper
    def check_email!(email, event)
      email_valid = if event.to_s == "overseas_student_auth"
                      MagicBean::OverseasStudentApplication.student_email_valid?(email)
                    else
                      MagicBean::OverseasStudentApplication.email_valid?(email)
                    end
      response_error(I18n.t("error.student_email.invalid_format")) unless email_valid
    end

    def check_email_verification_code!(email, verification_code, event)
      response_error(I18n.t("error.common.missing_verification_code")) if verification_code.blank?
      vc = MagicBean::EmailVerificationCode.public_send("build_#{event}_object", email)
      response_error(I18n.t("error.mobile.invalid_code")) unless vc.verify(verification_code)
      vc.code = nil
    end

    def shopline_check_email_verification_code!(email, verification_code, event)
      response_shopline_error(I18n.t("error.common.missing_verification_code", locale: :en)) if verification_code.blank?
      vc = MagicBean::EmailVerificationCode.public_send("build_#{event}_object", email)
      response_shopline_error(I18n.t("error.mobile.invalid_code", locale: :en)) unless vc.verify(verification_code)
      vc.code = nil
    end
  end
end
