# frozen_string_literal: true

class AddParentCategoryIdToCustomLists < ActiveRecord::Migration[5.2]
  def change
    add_column :custom_lists, :parent_category_id, :integer

    add_index :custom_lists, :parent_category_id
  end
end
