# frozen_string_literal: true

class CreateMultiLangConfigs < ActiveRecord::Migration[5.2]
  def change
    create_table :multi_lang_configs do |t|
      t.string :key, null: false
      t.string :name, null: false
      t.integer :kind, default: 0
      t.references :store, foreign_key: true

      t.timestamps
    end

    reversible do |dir|
      dir.up do
        MagicBean::MultiLangConfig.create_translation_table! value: :string
      end

      dir.down do
        MatchData::MultiLangConfig.drop_translation_table!
      end
    end
  end
end
