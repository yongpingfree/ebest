# frozen_string_literal: true

class AddBgColorToCategories < ActiveRecord::Migration[5.2]
  def change
    add_column :categories, :bg_color, :string, default: "#FFFFFF"
  end
end
