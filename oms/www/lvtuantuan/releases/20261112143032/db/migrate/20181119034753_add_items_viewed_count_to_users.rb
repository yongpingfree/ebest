# frozen_string_literal: true

class AddItemsViewedCountToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :items_viewed_count, :integer, null: false, default: 0
  end
end
