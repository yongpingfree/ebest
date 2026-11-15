# frozen_string_literal: true

class AddQuantityUpdatedAtToTimeLimitedPromotionPrices < ActiveRecord::Migration[5.2]
  def change
    add_column :time_limited_promotion_prices, :quantity_updated_at, :datetime
  end
end
