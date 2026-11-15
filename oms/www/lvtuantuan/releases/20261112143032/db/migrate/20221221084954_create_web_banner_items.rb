# frozen_string_literal: true

class CreateWebBannerItems < ActiveRecord::Migration[5.2]
  def change
    create_table :web_banner_items do |t|
      t.references :web_banner, foreign_key: true
      t.integer :position, null: false, default: 1
      t.string :mobile_image_url, null: false
      t.string :desktop_image_url, null: false
      t.datetime :start_at
      t.datetime :end_at

      t.timestamps
    end
  end
end
