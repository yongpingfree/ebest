# frozen_string_literal: true
class RemoveItemIdsFromCustomLists < ActiveRecord::Migration[5.2]
  def change
    remove_column :custom_lists, :item_ids, :integer, default: [], array: true
  end
end
