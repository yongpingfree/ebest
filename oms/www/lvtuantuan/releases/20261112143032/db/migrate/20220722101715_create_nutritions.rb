# frozen_string_literal: true

class CreateNutritions < ActiveRecord::Migration[5.2]
  def change
    create_table :nutritions do |t|
      t.string :slug

      t.timestamps
    end

    add_index :nutritions, :slug, unique: true

    reversible do |dir|
      dir.up do
        MagicBean::Nutrition.create_translation_table! name: :string
      end

      dir.down do
        MagicBean::Nutrition.drop_translation_table!
      end
    end
  end
end
