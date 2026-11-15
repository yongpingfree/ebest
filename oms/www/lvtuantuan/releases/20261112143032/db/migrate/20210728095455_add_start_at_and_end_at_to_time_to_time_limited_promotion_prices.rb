# frozen_string_literal: true

class AddStartAtAndEndAtToTimeToTimeLimitedPromotionPrices < ActiveRecord::Migration[5.2]
  def change
    add_column :time_limited_promotion_prices, :start_at, :datetime
    add_column :time_limited_promotion_prices, :end_at, :datetime
    add_column :time_limited_promotion_prices, :enabled, :boolean, default: false
    add_belongs_to :time_limited_promotion_prices, :store

    add_index :time_limited_promotion_prices, [:store_id, :enabled]
  end
end
