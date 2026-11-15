# frozen_string_literal: true

class CreateAfterSalesOrderItems < ActiveRecord::Migration[5.2]
  def change
    create_table :after_sales_order_items do |t|
      t.references :order_item, foreign_key: true
      t.references :after_sale, foreign_key: true
      t.integer :quantity, null: false, default: 1

      t.timestamps
    end
  end
end
