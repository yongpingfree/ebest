# frozen_string_literal: true

class CreateWebCustomLists < ActiveRecord::Migration[5.2]
  def change
    create_table :web_custom_lists do |t|
      t.integer :position, default: 1
      t.boolean :displayed, default: false
      t.boolean :items_shuffled, default: false
      t.references :store, foreign_key: true

      t.timestamps
    end

    reversible do |dir|
      dir.up do
        MagicBean::WebCustomList.create_translation_table! title: :string
      end

      dir.down do
        MagicBean::WebCustomList.drop_translation_table!
      end
    end

  end
end
