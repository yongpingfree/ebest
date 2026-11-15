# frozen_string_literal: true

module Wms::Helpers
  module AuthenticationHelper
    def require_authentication?
      return true if Rails.env.production?
      !(request.path =~ /doc|examples/) && (params[:skip_authenticate].blank? || params[:skip_authenticate].eql?("false"))
    end

    # Validates the token and user and sets the @current_user scope
    def authenticate!
      if require_authentication?
        timestamp = params[:timestamp]

        if (Time.current - 5.minutes).to_i > timestamp.to_i
          response_error "时间戳已过期", 401
        end

        unless params[:sign].eql? sign(timestamp)
          response_error "合作者签名验证不通过！", 401
        end
      end
    end

    def sign(timestamp)
      wms_key = Rails.application.credentials.dig(Rails.env.to_sym, :wms, :key)
      Digest::MD5.hexdigest("#{wms_key}#{timestamp}")
    end
  end
end
