# frozen_string_literal: true

class AddIsTopToComments < ActiveRecord::Migration[5.2]
  def change
    add_column :comments, :is_top, :boolean, default: false
  end
end
