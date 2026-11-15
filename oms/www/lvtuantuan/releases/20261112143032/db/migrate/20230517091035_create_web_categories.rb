# frozen_string_literal: true

class CreateWebCategories < ActiveRecord::Migration[5.2]
  def change
    create_table :web_categories do |t|
      t.bigint :parent_id
      t.integer :status, default: 1, null: false
      t.integer :position, default: 0, null: false
      t.string :icon
      t.string :bg_color
      t.integer :display_length, default: 5
      t.string :filter_icon
      t.boolean :can_create_invoice, default: true
      t.integer :sort_item_ids, default: [], array: true
      t.boolean :need_age_verification, default: false

      t.timestamps
    end

    add_index :web_categories, :parent_id

    reversible do |dir|
      dir.up do
        MagicBean::WebCategory.create_translation_table! name: :string
      end

      dir.down do
        MagicBean::WebCategory.drop_translation_table!
      end
    end
  end
end
