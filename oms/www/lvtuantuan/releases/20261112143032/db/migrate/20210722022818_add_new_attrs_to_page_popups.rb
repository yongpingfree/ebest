# frozen_string_literal: true

class AddNewAttrsToPagePopups < ActiveRecord::Migration[5.2]
  def change
    add_column :page_popups, :is_always, :boolean, default: false
    add_column :page_popups, :is_fullscreen, :boolean, default: false
  end
end
