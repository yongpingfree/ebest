# frozen_string_literal: true

class AddItemsShuffledCustomLists < ActiveRecord::Migration[5.2]
  def change
    add_column :custom_lists, :items_shuffled, :boolean, default: false
  end
end
