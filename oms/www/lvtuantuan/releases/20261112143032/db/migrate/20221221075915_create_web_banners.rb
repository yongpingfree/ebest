# frozen_string_literal: true

class CreateWebBanners < ActiveRecord::Migration[5.2]
  def change
    create_table :web_banners do |t|
      t.integer :page_location, null: false
      t.string :remark
      t.boolean :displayed, default: false
      t.references :store, foreign_key: true

      t.timestamps
    end
  end
end
