# frozen_string_literal: true

class AddShowOnWebToCategories < ActiveRecord::Migration[5.2]
  def change
    add_column :categories, :show_on_web, :boolean, default: false
  end
end
