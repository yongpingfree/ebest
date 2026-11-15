# frozen_string_literal: true

class AddShortTitleToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :short_title, :string
    add_column :products, :short_title, :string
    add_column :order_items, :short_title, :string
  end
end
