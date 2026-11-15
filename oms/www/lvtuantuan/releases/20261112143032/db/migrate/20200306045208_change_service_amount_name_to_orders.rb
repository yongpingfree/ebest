# frozen_string_literal: true

class ChangeServiceAmountNameToOrders < ActiveRecord::Migration[5.2]
  def change
    rename_column :orders, :credit_card_service_amount_in_cent, :credit_card_service_percentage
    rename_column :orders, :wechat_service_amount_in_cent, :wechat_service_percentage
  end
end
