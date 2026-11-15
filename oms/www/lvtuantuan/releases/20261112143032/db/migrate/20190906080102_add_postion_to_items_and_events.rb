# frozen_string_literal: true

class AddPostionToItemsAndEvents < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :position, :integer, default: 0
    add_column :pages, :position, :integer, default: 0
  end
end
