# frozen_string_literal: true

class CreateAfterSales < ActiveRecord::Migration[5.2]
  def change
    create_table :after_sales do |t|
      t.string :refund_no
      t.integer :after_sale_type, default: 1
      t.integer :status, default: 1
      t.datetime :agreed_at
      t.string :reason
      t.integer :amount_in_cent
      t.integer :quantity
      t.references :user
      t.references :order_item
      t.references :order

      t.timestamps
    end
  end
end
