# frozen_string_literal: true

class TranslateItems < ActiveRecord::Migration[5.2]
  def change
    reversible do |dir|
      dir.up do
        MagicBean::Item.create_translation_table!({
          title: :string,
          description: :text,
          shared_description: :string
        }, {
          migrate_data: true,
          remove_source_columns: true
        })
      end

      dir.down do
        MagicBean::Item.drop_translation_table! migrate_data: true
      end
    end
  end
end
