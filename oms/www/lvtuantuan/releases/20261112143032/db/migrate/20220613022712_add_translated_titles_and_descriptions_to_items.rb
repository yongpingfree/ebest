# frozen_string_literal: true

class AddTranslatedTitlesAndDescriptionsToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :translated_searchable_title, :string
    add_column :items, :translated_searchable_description, :string
  end
end
