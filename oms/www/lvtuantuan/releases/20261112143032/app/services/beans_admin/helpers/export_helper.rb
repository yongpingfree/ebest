# frozen_string_literal: true

module BeansAdmin::Helpers
  module ExportHelper
    def check_export_list_count
      redis_list_count_key = "export_list_count"
      redis_list_count = Rails.cache.fetch(redis_list_count_key) || 0
      response_error("已有3个导出任务正在执行，请稍后再试。") if redis_list_count >= 3
      Rails.cache.write(redis_list_count_key, redis_list_count += 1, expires_in: 10.minutes)
    end

    def decrease_export_list_count
      redis_list_count_key = "export_list_count"
      redis_list_count = Rails.cache.fetch(redis_list_count_key)
      Rails.cache.write(redis_list_count_key, redis_list_count -= 1, expires_in: 10.minutes) if redis_list_count&.positive?
    end
  end
end
