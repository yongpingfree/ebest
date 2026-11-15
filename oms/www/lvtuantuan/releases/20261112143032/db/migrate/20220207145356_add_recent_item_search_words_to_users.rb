# frozen_string_literal: true

class AddRecentItemSearchWordsToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :recent_item_search_words, :text, default: [], array: true
  end
end
