# frozen_string_literal: true

class AddTranslatedTitleToQaAndGuarantees < ActiveRecord::Migration[5.2]
  def change
    reversible do |dir|
      dir.up do
        MagicBean::QaAndGuarantee.add_translation_fields!({
          title: :string
        }, {
          migrate_data: true,
          remove_source_columns: true
        })
      end

      dir.down do
        remove_column :qa_and_guarantee_translations, :title
      end
    end
  end
end
