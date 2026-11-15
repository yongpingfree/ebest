# frozen_string_literal: true

class AddPositionAndStatusAndIconToCategories < ActiveRecord::Migration[5.2]
  def change
    add_column :categories, :status, :integer, default: 1
    add_column :categories, :position, :integer, default: 0
    add_column :categories, :icon, :string
  end
end
