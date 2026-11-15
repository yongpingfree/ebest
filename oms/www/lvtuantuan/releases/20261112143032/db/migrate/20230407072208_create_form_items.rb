# frozen_string_literal: true

class CreateFormItems < ActiveRecord::Migration[5.2]
  def change
    create_table :form_items do |t|
      t.integer :listing_type
      t.belongs_to :category
      t.integer :parent_category_id
      t.integer :minor_category_id
      t.string :cover
      t.string :main_images, default: [], array: true
      t.string :detail_images, default: [], array: true
      t.string :form_options, default: [], array: true
      t.string :notification_emails, comment: "多个email用分号隔开"
      t.string :translated_searchable_title
      t.string :translated_searchable_description
      t.belongs_to :store
      t.string :channels, default: [], array: true

      t.timestamps
    end

    add_index :form_items, :parent_category_id
    add_index :form_items, :minor_category_id

    reversible do |dir|
      dir.up do
        MagicBean::FormItem.create_translation_table!(
          {
            title: :string,
            description: :text,
          })
      end

      dir.down do
        MagicBean::FormItem.drop_translation_table!
      end
    end
  end
end
