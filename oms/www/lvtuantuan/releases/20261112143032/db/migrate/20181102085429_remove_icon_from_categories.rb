# frozen_string_literal: true

class RemoveIconFromCategories < ActiveRecord::Migration[5.2]
  def change
    remove_column :categories, :icon, :string
  end
end
