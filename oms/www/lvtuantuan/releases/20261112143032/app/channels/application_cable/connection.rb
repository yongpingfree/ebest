# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user_id
    identified_by :current_user
    identified_by :scene

    def connect
      self.current_user_id = find_current_user_id
      self.current_user = find_current_user
      self.scene = find_scene
    end

    def current_user_ip
      request.remote_ip
    end

    def current_device_id
      params[:device_id]
    end

    def params
      request.query_parameters
    end

    private

    def find_current_user_id
      if certificate
        MagicBean::User.where(ebest_platform_unionid: certificate.to_s)
                       .or(MagicBean::User.where(id: certificate))
                       .first.id
      else
        # 游客用户以设备 ID / IP 来区分独立用户
        current_device_id || current_user_ip
      end
    end

    def find_current_user
      if current_user_id.to_i.to_s == current_user_id.to_s
        MagicBean::User.find_by(id: current_user_id)
      end
    end

    def find_scene
      params[:scene]
    end

    def certificate
      payload["certificate"] if payload
      @certificate ||= (payload ? payload["certificate"] : nil)
    end

    def payload
      ActiveSupport::HashWithIndifferentAccess.new(
        JsonWebToken.decode(params[:token])[0]
      )
    rescue
      nil
    end
  end
end
