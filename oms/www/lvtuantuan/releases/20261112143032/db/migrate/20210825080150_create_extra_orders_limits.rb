# frozen_string_literal: true

class CreateExtraOrdersLimits < ActiveRecord::Migration[5.2]
  def change
    create_table :extra_orders_limits do |t|

      t.integer :order_amount_in_cent, null: false
      t.date :delivery_date, null: false
      t.datetime :begin_at, null: false
      t.integer :extra_merchant_delivery_orders_limit, null: false
      t.belongs_to :store

      t.timestamps
    end

    add_index :extra_orders_limits, [:store_id, :delivery_date], unique: true
  end
end
