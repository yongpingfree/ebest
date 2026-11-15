# frozen_string_literal: true

class CreateStockKeepingUnits < ActiveRecord::Migration[5.2]
  def change
    create_table :stock_keeping_units do |t|
      t.string :properties
      t.integer :quantity, default: 0
      t.integer :price_in_cent, default: 0
      t.string :image
      t.integer :position, default: 0
      t.integer :comments_count, default: 0
      t.references :item

      t.timestamps
    end
  end
end
