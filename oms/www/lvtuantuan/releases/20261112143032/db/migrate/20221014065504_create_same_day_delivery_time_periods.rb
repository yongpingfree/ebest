# frozen_string_literal: true

class CreateSameDayDeliveryTimePeriods < ActiveRecord::Migration[5.2]
  def change
    create_table :same_day_delivery_time_periods do |t|

      t.string :time_period
      t.integer :kind
      t.integer :time_window
      t.integer :address_count_limit
      t.boolean :enabled, default: true
      t.bigint :same_day_delivery_time_id
      t.index :same_day_delivery_time_id, name: "index_delivery_time_periods_on_same_day_delivery_time_id"

      t.timestamps
    end
  end
end
