# frozen_string_literal: true
class CreateTimeLimitedPromotions < ActiveRecord::Migration[5.2]
  def change
    create_table :time_limited_promotions do |t|
      t.string :title, null: false
      t.datetime :start_at, null: false
      t.datetime :end_at, null: false
      t.boolean :enabled, default: false
      t.references :store, foreign_key: true

      t.timestamps
    end
  end
end
