# frozen_string_literal: true

class AddSearchColumnsToShareSettings < ActiveRecord::Migration[5.2]
  def change
    add_column :share_settings, :search_words, :string
    add_column :share_settings, :search_cover, :string
  end
end
