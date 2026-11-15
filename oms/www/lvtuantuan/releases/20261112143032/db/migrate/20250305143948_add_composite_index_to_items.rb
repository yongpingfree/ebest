# frozen_string_literal: true

class AddCompositeIndexToItems < ActiveRecord::Migration[5.2]
  def change
    add_index :items, [:store_id, :parent_category_id, :category_id]
  end
end
