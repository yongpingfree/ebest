# frozen_string_literal: true

class AddUniqueIndexToSku < ActiveRecord::Migration[5.2]
  def change
    add_index :stock_keeping_units, [:item_id, :properties], unique: true
  end
end
