# frozen_string_literal: true

class CreateSkuProperties < ActiveRecord::Migration[5.2]
  def change
    create_table :sku_properties do |t|
      t.string :text

      t.timestamps
    end
  end
end
