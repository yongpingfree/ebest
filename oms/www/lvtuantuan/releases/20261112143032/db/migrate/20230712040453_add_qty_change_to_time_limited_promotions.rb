# frozen_string_literal: true

class AddQtyChangeToTimeLimitedPromotions < ActiveRecord::Migration[5.2]
  def change
    add_column :time_limited_promotions, :save_qty_to_promotion_price, :boolean, default: false, comment: '限时优惠活动期间添加库存到优惠库存'
  end
end
