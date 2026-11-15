# frozen_string_literal: true

class CreateAppDownChannels < ActiveRecord::Migration[5.2]
  def change
    create_table :app_download_channels do |t|
      t.string :code
      t.string :name
      t.string :qrcode
      t.integer :ios_views_count, default: 0
      t.integer :android_views_count, default: 0
      t.integer :other_views_count, default: 0

      t.timestamps
    end
  end
end
