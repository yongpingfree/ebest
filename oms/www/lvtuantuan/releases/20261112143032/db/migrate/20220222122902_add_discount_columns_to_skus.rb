# frozen_string_literal: true

class AddDiscountColumnsToSkus < ActiveRecord::Migration[5.2]
  def change
    add_column :stock_keeping_units, :discount_quantity, :integer
    add_column :stock_keeping_units, :discount_price_in_cent, :integer
  end
end
