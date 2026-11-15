# frozen_string_literal: true

class TranslateSkuValues < ActiveRecord::Migration[5.2]
  def change
    reversible do |dir|
      dir.up do
        MagicBean::SkuValue.create_translation_table!({
          text: :string
        }, {
          migrate_data: true,
          remove_source_columns: true
        })
      end

      dir.down do
        MagicBean::SkuValue.drop_translation_table! migrate_data: true
      end
    end
  end
end
