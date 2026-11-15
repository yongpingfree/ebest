# frozen_string_literal: true

class AddOrientationToWebCustomList < ActiveRecord::Migration[5.2]
  def change
    add_column :web_custom_lists, :orientation, :integer, default: 1, null: false, comment: "1: 横向, 2: 竖向"
  end
end
