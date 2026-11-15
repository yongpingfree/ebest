# frozen_string_literal: true

class PushNotifier
  class << self
    # 支持配置多个APP推送

    def user_client
      return @user_client if @user_client

      jpush_configs = Rails.application.credentials.dig(Rails.env.to_sym, :jpush)
      @user_client = JPush::Client.new(*jpush_configs.values_at(:app_key, :master_secret))
    end

    # Examples:
    #   => PushNotifier.push(:user, "You have a new message", 2, {})  # 2 is an user id
    #   => PushNotifier.push(:user, "You have a new message", [1, 2, 3], {})  # [1, 2, 3] an array consists
    #   => PushNotifier.push(:user, "You have a new message", :to_all, {}) # push to all devices
    def push(title, message, receiver_credential_ids = "ALL", extras = {})
      return if receiver_credential_ids.blank?

      pusher = user_client.pusher
      receiver_credential_ids = receiver_credential_ids.to_s == "ALL" ? [] : [*receiver_credential_ids].map { |v| "#{Rails.env}_#{v}" }
      audience = receiver_credential_ids.empty? ? "all" : JPush::Push::Audience.new.set_alias(receiver_credential_ids)
      notification = JPush::Push::Notification.new
        .set_alert(message)
        .set_ios(
          alert: message,
          extras: extras
        )
        .set_android(
          alert: message,
          title: title,
          extras: extras
        )

      payload = JPush::Push::PushPayload.new(
        platform: "all",
        audience: audience,
        notification: notification
      ).set_options({
        apns_production: Rails.env.production? || Rails.env.staging?
      })

      if debug?
        Rails.logger.debug "\nPushed message with payload: #{payload.to_json}\n"
      else
        result = pusher.push(payload)
        Rails.logger.debug "Pushed message: #{result}"

        result
      end
    end

    def debug?
      %w(development test).include? Rails.env
    end
  end
end
