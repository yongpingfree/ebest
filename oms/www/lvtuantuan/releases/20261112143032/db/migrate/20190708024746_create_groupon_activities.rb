# frozen_string_literal: true

class CreateGrouponActivities < ActiveRecord::Migration[5.2]
  def change
    create_table :groupon_activities do |t|
      t.integer :kind
      t.integer :price_in_cent, comment: "产品拼团价格"
      t.integer :user_count, comment: "拼团要求人数"
      t.datetime :start_at
      t.datetime :end_at
      t.boolean :enabled
      t.belongs_to :item

      t.timestamps
    end
  end
end
