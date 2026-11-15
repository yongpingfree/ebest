# frozen_string_literal: true
class AddFilterIconToCategories < ActiveRecord::Migration[5.2]
  def change
    add_column :categories, :filter_icon, :string
  end
end
