# frozen_string_literal: true

class AddIconToCustomLists < ActiveRecord::Migration[5.2]
  def change
    add_column :custom_lists, :icon, :string
  end
end
