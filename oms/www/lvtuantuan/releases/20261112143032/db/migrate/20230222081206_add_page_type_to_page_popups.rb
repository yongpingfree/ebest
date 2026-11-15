# frozen_string_literal: true

class AddPageTypeToPagePopups < ActiveRecord::Migration[5.2]
  def change
    add_column :page_popups, :page_type, :integer, default: 1
  end
end
