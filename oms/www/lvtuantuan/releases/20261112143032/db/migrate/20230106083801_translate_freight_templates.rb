# frozen_string_literal: true

class TranslateFreightTemplates < ActiveRecord::Migration[5.2]
  def change
    reversible do |dir|
      dir.up do
        MagicBean::FreightTemplate.create_translation_table!({
          name: :string
        }, {
          migrate_data: true,
          remove_source_columns: true
        })
      end

      dir.down do
        MagicBean::FreightTemplate.drop_translation_table! migrate_data: true
      end
    end
  end
end
