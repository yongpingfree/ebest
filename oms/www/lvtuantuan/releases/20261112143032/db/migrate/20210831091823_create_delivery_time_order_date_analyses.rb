# frozen_string_literal: true

class CreateDeliveryTimeOrderDateAnalyses < ActiveRecord::Migration[5.2]
  def change
    create_table :delivery_time_order_date_analyses do |t|

      t.integer :delivery_time_id
      t.date :delivery_date
      t.integer :distinct_address_count, default: 0

      t.timestamps
    end

    add_index :delivery_time_order_date_analyses, [:delivery_date, :delivery_time_id], unique: true, name: "delivery_time_order_on_delivery_date_and_delivery_time"
  end
end
