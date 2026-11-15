# frozen_string_literal: true

class AddActualCreditCardServicePercentageToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :actual_credit_card_service_percentage, :decimal, precision: 5, scale: 2, default: 0.0, comment: "实际信用卡服务费百分比"
  end
end
