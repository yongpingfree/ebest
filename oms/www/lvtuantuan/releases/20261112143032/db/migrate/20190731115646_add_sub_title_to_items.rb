# frozen_string_literal: true

class AddSubTitleToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :sub_title, :string
    add_column :items, :cover, :string
  end
end
