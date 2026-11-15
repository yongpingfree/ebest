# frozen_string_literal: true
class CreateGiftActivities < ActiveRecord::Migration[5.2]
  def change
    create_table :gift_activities do |t|
      t.datetime :start_at
      t.datetime :end_at
      t.integer :status, default: 1
      t.json :rules

      t.timestamps
    end

    add_reference :orders, :gift_activity
    add_column :orders, :gifts_properties, :json
  end
end
