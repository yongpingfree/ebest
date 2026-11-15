# frozen_string_literal: true

class AddBgColorToCustomLists < ActiveRecord::Migration[5.2]
  def change
    add_column :custom_lists, :bg_color, :string, default: "#FEEDDC"
    change_column_default :categories, :bg_color, "#FEEDDC"
  end
end
