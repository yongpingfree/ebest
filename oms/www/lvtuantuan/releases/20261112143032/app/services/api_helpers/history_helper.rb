# frozen_string_literal: true

module ApiHelpers
  module HistoryHelper
    def save_history
      return unless status.to_s[0] == "2"
      return unless current_user

      action_type = options.dig(:route_options, :action_type)
      page_type = options.dig(:route_options, :page_type)
      return unless action_type && page_type

      history_params =
        {
          action_type: action_type,
          page_type: page_type,
          options: {
            operator_id: current_user.id,
            store_id: current_store_id,
            channel: ebest_channel,
            params: params.to_json
          }
        }

      history_params_key = "history_params"
      Rails.cache.redis.rpush(history_params_key, history_params)
    end

    # 跟原来的历史记录有所区别，主要是跟商品相关，用于后续分析用户行为，给用户推荐商品
    def save_user_history
      return unless current_user

      history_params =
        {
          user_id: current_user.id,
          operatable_type: resource.class.name,
          operatable_id: resource.id,
          view_date: Date.current.to_s,
          channel: ebest_channel
        }

      Rails.cache.redis.rpush(MagicBean::UserHistory::REDIS_LIST_KEY, history_params)
    end

    def save_item_search_history_to_redis
      return unless current_user
      item_history_user_key = "item_history_user_#{current_user.id}-#{ebest_channel}"
      keyword = (params[:original_keyword].presence || params[:keyword].presence)&.join(" ")
      return unless keyword
      push_item_to_redis_list(item_history_user_key, keyword)
    end

    def push_item_to_redis_list(list_key, item)
      Rails.cache.redis.lrem(list_key, 0, item)
      Rails.cache.redis.lpush(list_key, item)
    end
  end
end
