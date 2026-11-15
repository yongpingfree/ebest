# frozen_string_literal: true

class CreateItemNutritionValues < ActiveRecord::Migration[5.2]
  def change
    create_table :item_nutrition_values do |t|
      t.references :item, foreign_key: true
      t.references :nutrition, foreign_key: true
      t.string :avg_qty_per_package
      t.string :avg_qty_per_100_units

      t.timestamps
    end
  end
end
