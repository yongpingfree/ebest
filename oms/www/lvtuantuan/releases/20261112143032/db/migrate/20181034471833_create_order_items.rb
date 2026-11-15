# frozen_string_literal: true

class CreateOrderItems < ActiveRecord::Migration[5.2]
  def change
    create_table :order_items do |t|
      t.integer :quantity, default: 0
      t.integer :amount_in_cent, default: 0, comment: "订单项总价"
      t.integer :price_in_cent, default: 0, comment: "订单项单价"
      t.references :stock_keeping_unit
      t.references :order

      t.timestamps
    end
  end
end
