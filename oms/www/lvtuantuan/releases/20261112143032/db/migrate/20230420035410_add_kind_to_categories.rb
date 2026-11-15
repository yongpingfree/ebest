# frozen_string_literal: true

class AddKindToCategories < ActiveRecord::Migration[5.2]
  def change
    add_column :categories, :goto_kind, :integer, default: 1, null: false
  end
end
