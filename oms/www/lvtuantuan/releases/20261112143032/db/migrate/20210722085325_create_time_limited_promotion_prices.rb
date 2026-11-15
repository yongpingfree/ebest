# frozen_string_literal: true
class CreateTimeLimitedPromotionPrices < ActiveRecord::Migration[5.2]
  def change
    create_table :time_limited_promotion_prices do |t|
      t.references :time_limited_promotion, foreign_key: true, index: { name: :index_time_limited_promotion_prices_on_tlp_id }
      t.references :stock_keeping_unit, foreign_key: true, index: { name: :index_time_limited_promotion_prices_on_sku_id }
      t.integer :price_in_cent, null: false

      t.timestamps
    end
  end
end
