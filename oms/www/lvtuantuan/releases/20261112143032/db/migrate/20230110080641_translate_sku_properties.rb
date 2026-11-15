# frozen_string_literal: true

class TranslateSkuProperties < ActiveRecord::Migration[5.2]
  def change
    reversible do |dir|
      dir.up do
        MagicBean::SkuProperty.create_translation_table!({
          text: :string
        }, {
          migrate_data: true,
          remove_source_columns: true
        })
      end

      dir.down do
        MagicBean::SkuProperty.drop_translation_table! migrate_data: true
      end
    end
  end
end
