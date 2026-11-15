# frozen_string_literal: true

class AddMinorCategoryIdToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :minor_category_id, :integer
    add_column :products, :minor_category_id, :integer

    add_index :items, :minor_category_id
    add_index :products, :minor_category_id
  end
end
