# frozen_string_literal: true

class AddReturnIntegralAmountToAfterSales < ActiveRecord::Migration[5.2]
  def change
    add_column :after_sales, :return_integral_amount, :integer, default: 0
    remove_column :after_sales, :total_price_in_cent, :integer, default: 0, null: false
  end
end
