# frozen_string_literal: true

class TranslateCustomLists < ActiveRecord::Migration[5.2]
  def change
    reversible do |dir|
      dir.up do
        MagicBean::CustomList.create_translation_table!({
          title: :string
        }, {
          migrate_data: true,
          remove_source_columns: true
        })
      end

      dir.down do
        MagicBean::CustomList.drop_translation_table! migrate_data: true
      end
    end
  end
end
