# frozen_string_literal: true

class AddAsCategoryAndPositionToCustomLists < ActiveRecord::Migration[5.2]
  def change
    add_column :custom_lists, :as_category, :boolean, default: false
    add_column :custom_lists, :position, :integer, default: 0
  end
end
