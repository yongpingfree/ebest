# frozen_string_literal: true

class AddNewAttrsToTimeLimitedPromotions < ActiveRecord::Migration[5.2]
  def change
    add_column :time_limited_promotions, :state, :integer, null: false, default: 0

    add_column :time_limited_promotion_prices, :quantity, :integer, comment: "优惠价库存"
    add_column :time_limited_promotion_prices, :reserved_quantity, :integer, comment: "预留的原价库存"
  end
end
