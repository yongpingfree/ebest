# frozen_string_literal: true

module CommonEntities
  class Model < Grape::Entity
    expose :id, documentation: { type: Integer }
    expose :created_at, :updated_at
    expose :cn do |obj|
      obj.class.name
    end

    expose :store_id do |obj|
      obj.store_id if obj.respond_to? :store_id
    end

    def ebest_channel
      options.dig(:env, "api.endpoint")&.ebest_channel
    end

    def current_user
      options.dig(:env, "api.endpoint")&.current_user
    end

    def current_store_id
      options.dig(:env, "api.endpoint")&.current_store_id || MagicBean::Current.store_id
    end

    def current_postal_code
      options.dig(:env, "api.endpoint")&.current_postal_code || MagicBean::Current.postal_code
    end

    def current_suburb
      options.dig(:env, "api.endpoint")&.current_suburb || MagicBean::Current.suburb
    end

    def default_avatar
      options.dig(:env, "api.endpoint")&.default_avatar
    end

    def self.float_expose(attribute, options = {})
      expose attribute, options do |obj, _|
        value = obj.public_send(attribute)
        value.to_f if value.present?
      end
    end

    def self.translate_expose(attribute, options = {})
      expose attribute, options
      I18n.available_locales.each do |locale|
        expose "#{attribute}_#{locale.to_s.underscore}".to_sym, options
      end
    end

    format_with(:integer) { |value| value.to_i }
    format_with(:float) { |value| value.to_f }

    # 22:00 -> 10 PM, 22:50 -> 10:50 PM
    def time_en_format(time_str)
      return nil if time_str.blank?

      time = time_str.in_time_zone
      if time.min.zero?
        time.strftime("%-l%P")
      else
        time.strftime("%-l:%M%P")
      end
    end

    def english_locale?
      I18n.locale.to_s.start_with?('en')
    end

    def date_strftime
      @date_strftime ||= I18n.t("grape.delivery.date_strftime")
    end
  end
end
