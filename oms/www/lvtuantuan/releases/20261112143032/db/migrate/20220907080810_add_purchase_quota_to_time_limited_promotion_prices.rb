# frozen_string_literal: true

class AddPurchaseQuotaToTimeLimitedPromotionPrices < ActiveRecord::Migration[5.2]
  def change
    add_column :time_limited_promotion_prices, :original_buy_quota, :integer, default: 0
    add_column :time_limited_promotion_prices, :original_buy_quota_days, :integer, default: 0
    add_column :time_limited_promotion_prices, :buy_quota, :integer, default: 0
    add_column :time_limited_promotion_prices, :buy_quota_days, :integer, default: 1
  end
end
