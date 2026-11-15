# frozen_string_literal: true

class CalculateItemsHotSellRankingJob < ApplicationJob
  queue_as :default

  include ::BeansAdmin::Helpers::HotSellConfigsHelper

  # 每晚凌晨自动计算热卖榜排行
  def perform
    MagicBean::Item.where.not(hot_sell_config_id: nil).update_all(hot_sell_ranking: nil, hot_sell_config_id: nil)

    MagicBean::HotSellConfig.where(enabled: true).find_each do |hot_sell_config|
      ranking_item_ids = sku_ids_order_by_sales(hot_sell_config)
      ranking_item_ids.each_with_index do |item_id, index|
        MagicBean::Item.find(item_id).update_columns(hot_sell_ranking: index + 1, hot_sell_config_id: hot_sell_config.id)
      end
    end
  end
end
