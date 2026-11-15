# frozen_string_literal: true
class CreateBannerClicks < ActiveRecord::Migration[5.2]
  def change
    create_table :banner_clicks do |t|
      t.date :date
      t.string :url, limit: 2048
      t.integer :count, default: 0

      t.timestamps
    end

    add_index :banner_clicks, [:url, :date], unique: true
  end
end
