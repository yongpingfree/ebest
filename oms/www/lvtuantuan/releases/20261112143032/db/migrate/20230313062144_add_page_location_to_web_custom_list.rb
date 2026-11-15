# frozen_string_literal: true

class AddPageLocationToWebCustomList < ActiveRecord::Migration[5.2]
  def change
    add_column :web_custom_lists, :page_location, :integer, null: false, default: 1
  end
end
