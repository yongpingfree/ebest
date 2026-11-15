# frozen_string_literal: true
module MagicBean
  class HotSellConfig < ApplicationRecord
    include ::BeansAdmin::Helpers::HotSellConfigsHelper

    validates :category_id, uniqueness: { scope: :store_id }
    validates :last_x_days, presence: true, numericality: { greater_than: 0 }
    validates :show_item_nums, presence: true, numericality: { greater_than: 0 }

    delegate :name, to: :category, prefix: true
    delegate :name, to: :store, prefix: true

    belongs_to :category
    belongs_to :store
    has_many :items, dependent: :nullify

    after_save :reset_items_ranking

    def mini_program_path; end

    def app_path
      { type: "hotSell", params: { id: id } }.to_json
    end

    private

    def reset_items_ranking
      return if saved_changes.blank?
      items.update_all(hot_sell_ranking: nil, hot_sell_config_id: nil)

      if enabled
        ranking_item_ids = sku_ids_order_by_sales(self)
        ranking_item_ids.each_with_index do |item_id, index|
          MagicBean::Item.find(item_id).update_columns(hot_sell_ranking: index + 1, hot_sell_config_id: id)
        end
      end
    end
  end
end
