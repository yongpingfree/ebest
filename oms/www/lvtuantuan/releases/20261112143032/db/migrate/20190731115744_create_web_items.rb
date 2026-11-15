# frozen_string_literal: true

class CreateWebItems < ActiveRecord::Migration[5.2]
  def change
    create_table :web_items do |t|
      t.string :video
      t.string :upper_images, array: true
      t.string :lower_images, array: true
      t.string :banner_images, array: true
      t.belongs_to :item, index: true

      t.timestamps
    end
  end
end
