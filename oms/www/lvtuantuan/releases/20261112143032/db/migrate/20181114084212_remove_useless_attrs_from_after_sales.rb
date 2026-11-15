# frozen_string_literal: true

class RemoveUselessAttrsFromAfterSales < ActiveRecord::Migration[5.2]
  def change
    remove_reference :after_sales, :order_item
    remove_column :after_sales, :quantity, :integer
  end
end
