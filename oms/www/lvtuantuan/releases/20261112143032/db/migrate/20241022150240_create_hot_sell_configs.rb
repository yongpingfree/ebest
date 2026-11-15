# frozen_string_literal: true

class CreateHotSellConfigs < ActiveRecord::Migration[5.2]
  def change
    create_table :hot_sell_configs do |t|
      t.integer :last_x_days, default: 14, comment: "过去X天销量"
      t.integer :show_item_nums, default: 30, comment: "最多展示几个商品"
      t.boolean :contains_order_gift, default: true, comment: "销量包含全场满赠数量"
      t.boolean :contains_order_pool_gift, default: true, comment: "销量包含优惠池满赠数量"
      t.boolean :is_show_storage_on_sale, default: true, comment: "仅展示有库存开卖商品"
      t.boolean :enabled, default: true, comment: "是否展示热卖榜"
      t.belongs_to :category
      t.belongs_to :store

      t.timestamps
    end
  end
end
