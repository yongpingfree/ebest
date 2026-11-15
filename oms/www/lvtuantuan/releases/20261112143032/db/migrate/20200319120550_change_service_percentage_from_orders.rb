# frozen_string_literal: true
class ChangeServicePercentageFromOrders < ActiveRecord::Migration[5.2]
  def change
    change_column :orders, :wechat_service_percentage, :float, default: 0
    change_column :orders, :credit_card_service_percentage, :float, default: 0
  end
end
