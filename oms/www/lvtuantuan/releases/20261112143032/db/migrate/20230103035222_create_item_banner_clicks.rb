# frozen_string_literal: true

class CreateItemBannerClicks < ActiveRecord::Migration[5.2]
  def change
    create_table :item_banner_clicks do |t|
      t.date :date
      t.integer :count, default: 0
      t.belongs_to :item_banner

      t.timestamps
    end

    add_index :item_banner_clicks, :date, unique: true
  end
end
