# frozen_string_literal: true

class AddTranslationsToHotSearches < ActiveRecord::Migration[5.2]
  def self.up
    MagicBean::HotSearch.create_translation_table!({
      word: :string
    }, {
      :migrate_data => true,
      :remove_source_columns => true
    })
  end

  def self.down
    MagicBean::HotSearch.drop_translation_table! migrate_data: true
  end
end
