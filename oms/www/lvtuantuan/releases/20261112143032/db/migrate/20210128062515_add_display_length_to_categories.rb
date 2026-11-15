# frozen_string_literal: true

class AddDisplayLengthToCategories < ActiveRecord::Migration[5.2]
  def change
    add_column :categories, :display_length, :integer, default: 5
  end
end
