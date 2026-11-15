# frozen_string_literal: true

module BeansApp
  class API::V1::Mine < ::API

    namespace :mine, desc: "我的 API" do
      helpers do
        def today_history_redis_data
          # 从redis获取当天的数据浏览数据, 由于用的是rpush, 需要lrange遍历所有数据，把当前用户的浏览数据过滤出来先
          today_item_ids, current_user_history_redis_index = [], []
          Rails.cache.redis.lrange(MagicBean::UserHistory::REDIS_LIST_KEY, 0, -1).reverse.each_with_index do |redis_history, index|
            user_history = eval redis_history
            if user_history[:operatable_type] == "MagicBean::Item" && user_history[:channel] == ebest_channel && user_history[:user_id] == current_user.id
              today_item_ids << user_history[:operatable_id]
              current_user_history_redis_index << index
            end
          end
          [today_item_ids, current_user_history_redis_index]
        end
      end

      get "page_info" do
        current_user.update_tracked_fields(ip_address)
        unread_push_messages_counter = current_user.calculate_push_messages_count(current_store_id)
        # 出现个别用户没有message_unread_counter，所以需要初始化
        unread_text_messages_counter = (current_user.message_unread_counter || current_user.send(:init_message_unread_counter))
        total_unread_messages_count = unread_push_messages_counter["promotion"] +
                                      unread_push_messages_counter["service_notification"] +
                                      unread_text_messages_counter.order_tracking_count +
                                      unread_text_messages_counter.customer_service_count +
                                      unread_text_messages_counter.sku_in_stock_count


        {
          unpaid_orders_count: current_user.orders.wait_buyer_pay.count,
          not_closed_groupons_count: current_user.groupons.not_closed.count,
          unused_coupons_count: current_user.coupons.pending.where(store_id: [nil, current_store_id]).count,
          unread_replies_count: 0, # TODO 反馈功能完善后再返回正确数值
          unread_promotion_push_messages_count: unread_push_messages_counter["promotion"],
          unread_service_notification_push_messages_count: unread_push_messages_counter["service_notification"],
          unread_order_tracking_messages_count: unread_text_messages_counter.order_tracking_count,
          unread_customer_service_messages_count: unread_text_messages_counter.customer_service_count,
          unread_sku_in_stock_messages_count: unread_text_messages_counter.sku_in_stock_count,
          total_unread_messages_count: total_unread_messages_count,
          unread_push_messages_count: 0 # NOTE: 保留原有的未读消息数字段，用户都升级 app 后可以去掉
        }
      end

      # 获取用户最近30天浏览记录，查询user_histories表，根据view_date进行分组，获取对应operatable_id
      get "user_histories" do
        has_today_data = false
        @groupon_activities = MagicBean::GrouponActivity.published.going

        today_item_ids, _ = today_history_redis_data
        today_items = if today_item_ids.present?
          MagicBean::Item.includes(:translations, :on_sale_skus).where(id: today_item_ids).reorder_by_ids(today_item_ids)
        else
          []
        end

        histories = current_user.user_histories.includes(operatable: [:translations, :on_sale_skus]).where(deleted_at: nil).where("view_date > ?", 30.days.ago.to_date).send(ebest_channel)
          .where(operatable_type: "MagicBean::Item").order(created_at: :desc).group_by(&:view_date).map do |k, v|          
          items = v.map(&:operatable)
          if k == Date.current
            has_today_data = true
            items = (today_items + items).uniq
          end

          {
            view_date: k,
            items: BeansApp::API::Entities::MinimalItem.represent(items, groupon_activities: @groupon_activities, is_new_user: is_new_user, active_top_left_item_hash: active_top_left_item_hash, exclusive_coupon_item_info: exclusive_coupon_item_info, buy_n_discount_item_info: buy_n_discount_item_info, preferential_pool_item_infos: preferential_pool_item_infos, allow_view_same_tag_items_info: allow_view_same_tag_items_info)
          }
        end

        # 如果今天没有数据，但是redis有今天浏览记录，需要把数据加入到历史记录中
        if !has_today_data && today_items.present?
          today_history = [
            {
              view_date: Date.current,
              items: BeansApp::API::Entities::MinimalItem.represent(today_items, groupon_activities: @groupon_activities, is_new_user: is_new_user, active_top_left_item_hash: active_top_left_item_hash, exclusive_coupon_item_info: exclusive_coupon_item_info, buy_n_discount_item_info: buy_n_discount_item_info, preferential_pool_item_infos: preferential_pool_item_infos, allow_view_same_tag_items_info: allow_view_same_tag_items_info)
            }
          ]
          histories = today_history + histories
        end
       
        histories        
      end

      # 清空用户浏览记录，软删除user_histories表中的数据，并清空相关redis数据
      delete "user_histories" do
        current_user.user_histories.update_all(deleted_at: Time.current)

        # 清空今天redis history数据
        _, current_user_history_redis_index = today_history_redis_data

        current_user_history_redis_index.each do |index|
          Rails.cache.redis.lset MagicBean::UserHistory::REDIS_LIST_KEY, index, "DELETED"
        end
        Rails.cache.redis.lrem(MagicBean::UserHistory::REDIS_LIST_KEY, 0, "DELETED")       

        response_success
      end
    end
  end
end
