# frozen_string_literal: true

class TranslateQaAndGuagrantees < ActiveRecord::Migration[5.2]
  def change
    reversible do |dir|
      dir.up do
        MagicBean::QaAndGuarantee.create_translation_table!({
          image: :string
        }, {
          migrate_data: true,
          remove_source_columns: true
        })
      end

      dir.down do
        MagicBean::QaAndGuarantee.drop_translation_table! migrate_data: true
      end
    end
  end
end
