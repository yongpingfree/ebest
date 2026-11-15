# frozen_string_literal: true

class AddUniqIndexToSkus < ActiveRecord::Migration[5.2]
  def change
    add_index :stock_keeping_units, [:no, :store_id], unique: true
  end
end
