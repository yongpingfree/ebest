# frozen_string_literal: true

class AddTotalFieldsToAfterSales < ActiveRecord::Migration[5.2]
  def change
    add_column :after_sales, :total_price_in_cent, :integer, null: false, default: 0
    add_column :after_sales, :total_quantity, :integer, null: false, default: 0
  end
end
