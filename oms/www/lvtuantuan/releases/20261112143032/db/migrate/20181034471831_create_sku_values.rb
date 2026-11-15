# frozen_string_literal: true

class CreateSkuValues < ActiveRecord::Migration[5.2]
  def change
    create_table :sku_values do |t|
      t.string :text
      t.references :sku_property

      t.timestamps
    end
  end
end
