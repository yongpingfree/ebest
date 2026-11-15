# frozen_string_literal: true

class CreateItemTags < ActiveRecord::Migration[5.2]
  def change
    create_table :item_tags do |t|
      t.belongs_to :item_tag_group

      t.timestamps
    end

    reversible do |dir|
      dir.up do
        MagicBean::ItemTag.create_translation_table! name: :string
      end

      dir.down do
        MagicBean::ItemTag.drop_translation_table!
      end
    end
  end
end
