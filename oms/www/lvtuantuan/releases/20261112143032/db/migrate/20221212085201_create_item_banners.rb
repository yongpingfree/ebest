# frozen_string_literal: true

class CreateItemBanners < ActiveRecord::Migration[5.2]
  def change
    create_table :item_banners do |t|

      t.string :title
      t.string :banner
      t.integer :item_ids, array: true, default: []
      t.datetime :start_at
      t.datetime :end_at
      t.integer :click_count, default: 0
      t.string :path, comment: "跳转路径"
      t.boolean :enabled, default: false
      t.timestamps
    end
  end
end
