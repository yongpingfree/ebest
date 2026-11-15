# frozen_string_literal: true

class SaveUserHistoryJob < ApplicationJob
  queue_as :low_priority

  def perform
    history_params_key = MagicBean::UserHistory::REDIS_LIST_KEY
    params_count = Rails.cache.redis.llen(history_params_key)
    MagicBean::UserHistory.transaction do
      (1..params_count).each do
        params = eval Rails.cache.redis.lpop(history_params_key)
        user_history = MagicBean::UserHistory.find_by(user_id: params[:user_id], operatable_type: params[:operatable_type], operatable_id: params[:operatable_id], view_date: params[:view_date], channel: params[:channel])
        if user_history
          user_history.increment!(:count)
        else
          MagicBean::UserHistory.create(user_id: params[:user_id], operatable_type: params[:operatable_type], operatable_id: params[:operatable_id], view_date: params[:view_date], channel: params[:channel], count: 1)
        end
      end
    end
  end
end
