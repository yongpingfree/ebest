# frozen_string_literal: true

class SaveHistoryJob < ApplicationJob
  queue_as :low_priority

  def perform(*)
    history_params_key = "history_params"
    params_count = Rails.cache.redis.llen(history_params_key)
    MagicBean::History.transaction do
      (1..params_count).each do
        history_params = eval Rails.cache.redis.lpop(history_params_key)
        options = history_params[:options]
        params = ActiveSupport::JSON.decode(options[:params])
        operator = MagicBean::User.find_by(id: options[:operator_id])
        next unless operator
        MagicBean::History.create(operator: operator, action_type: history_params[:action_type], page_type: history_params[:page_type], store_id: options[:store_id], channel: options[:channel], params: params)
      end
    end
  end
end
