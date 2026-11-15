# frozen_string_literal: true

class AddSortItemIdsToCategories < ActiveRecord::Migration[5.2]
  def change
    add_column :categories, :sort_item_ids, :integer, array: true, default: []
  end
end
