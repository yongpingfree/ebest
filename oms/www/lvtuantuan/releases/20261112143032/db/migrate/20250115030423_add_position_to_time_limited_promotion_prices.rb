# frozen_string_literal: true

class AddPositionToTimeLimitedPromotionPrices < ActiveRecord::Migration[5.2]
  def change
    add_column :time_limited_promotion_prices, :position, :integer, comment: "权重，值越小，排序越靠前"
  end
end
