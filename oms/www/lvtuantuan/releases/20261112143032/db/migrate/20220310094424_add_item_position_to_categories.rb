# frozen_string_literal: true

class AddItemPositionToCategories < ActiveRecord::Migration[5.2]
  def change
    add_column :categories, :item_position, :integer, default: 99999999
  end
end
