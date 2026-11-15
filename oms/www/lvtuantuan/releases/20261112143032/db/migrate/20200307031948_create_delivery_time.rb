# frozen_string_literal: true

class CreateDeliveryTime < ActiveRecord::Migration[5.2]
  def change
    create_table :delivery_times do |t|
      t.string :name, comment: "名称"
      t.string :weekdays, array: true, default: []
      t.string :time_period, array: true, default: []

      t.timestamps null: false
    end
  end
end
