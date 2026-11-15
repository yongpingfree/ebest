# frozen_string_literal: true

module MagicBean
  class AppNotifier

    # users支持以下数据类型
    # NilClass
    # - nil
    #
    # Integer
    # - 1
    #
    # String
    # - "1"
    #
    # Array
    # - []
    # - [1, 2, 3]

    def self.enqueue_app_push_job(title, message, user_ids, extras = {})
      return if Rails.env.test? || Rails.env.development?
      return if user_ids.blank?
      # 黑名单不接收推送的用户
      push_disabled_user_ids = MagicBean::MobileBlacklist.active.where(push_notification_disabled: true, user_id: user_ids).map(&:user_id)

      Sidekiq.redis do |redis|
        redis.multi do
          if (user_ids.is_a?(Integer) || user_ids.is_a?(String)) && push_disabled_user_ids.blank?
            push_notice_to_all_platform(user_ids, title, message, extras)
          elsif user_ids.is_a?(Array)
            tmp_user_ids = user_ids - push_disabled_user_ids
            tmp_user_ids.in_groups_of(1000, false).each do |ids|
              push_notice_to_all_platform(ids, title, message, extras)
            end
          end
        end
      end
    end

    def self.push_notice_to_all_platform(target_value, title, message, extras = {})
      # 这里改为调用阿里云推送
      AliyunPushNotificationJob.perform_later(target_value, title, message, extras.to_json)
    end
  end
end
