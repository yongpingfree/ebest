# frozen_string_literal: true

class CreateProducts < ActiveRecord::Migration[5.2]
  def change
    create_table :products do |t|

      t.string :title
      t.string :title_en
      t.text :description
      t.string :shared_description
      t.string :cover
      t.string :share_cover
      t.string :main_images, array: true, default: []
      t.string :detail_video
      t.string :detail_images, array: true, default: []
      t.integer :actual_monthly_sales_count, default: 0, null: false
      t.belongs_to :category
      t.belongs_to :brand
      t.belongs_to :store

      t.timestamps
    end
  end
end
