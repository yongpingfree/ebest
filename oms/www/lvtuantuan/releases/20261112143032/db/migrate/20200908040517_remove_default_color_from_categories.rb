# frozen_string_literal: true

class RemoveDefaultColorFromCategories < ActiveRecord::Migration[5.2]
  def change
    change_column_default :categories, :bg_color, nil
  end
end
