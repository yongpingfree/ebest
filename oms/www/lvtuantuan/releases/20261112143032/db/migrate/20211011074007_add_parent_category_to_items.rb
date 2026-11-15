# frozen_string_literal: true
class AddParentCategoryToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :parent_category_id, :integer

    add_index :items, :parent_category_id
  end
end
