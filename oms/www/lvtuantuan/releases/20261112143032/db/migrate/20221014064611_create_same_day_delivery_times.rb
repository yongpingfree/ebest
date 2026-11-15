# frozen_string_literal: true

class CreateSameDayDeliveryTimes < ActiveRecord::Migration[5.2]
  def change
    create_table :same_day_delivery_times do |t|

      t.string :name
      t.string :weekdays, default: [], array: true
      t.boolean :limited_by_orders_limit_every_day, default: true

      t.timestamps
    end
  end
end
