# frozen_string_literal: true

module BeansAdmin::Helpers
  module ResourceHelper
    include ::ApiHelpers::BaseResourceHelper

    def entity_namespace_name
      "BeansAdmin::API::Entities"
    end

    def validate_export_datetime_params(start_time, end_time)
      response_error("时间必须全填或全不填") if [start_time.present?, end_time.present?].count(true) == 1

      response_error("开始时间必须小于或等于结束时间") if start_time.present? && end_time.present? && start_time > end_time

      response_error("时间周期只能在一年内") if start_time.present? && end_time.present? && (end_time.to_date - start_time.to_date > 365)
    end

    def validate_export_date_params(start_day, end_day, allow_same_day = true)
      response_error("日期必须全填或全不填") if [start_day.present?, end_day.present?].count(true) == 1

      response_error("周期只能在一年内") if start_day.present? && end_day.present? && (end_day - start_day > 365)

      response_error("周期必须大于1天") if !allow_same_day && start_day.present? && end_day.present? && end_day == start_day
    end

    def encrypt_params(options)
      options = ActiveSupport::JSON.encode(options)
      DataEncrypt.aes128_encrypt(options)
    end
  end
end
