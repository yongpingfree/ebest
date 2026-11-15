# frozen_string_literal: true

class AddWeightToSkus < ActiveRecord::Migration[5.2]
  def change
    add_column :stock_keeping_units, :weight_in_gram, :integer, default: 0, null: false
    add_column :order_items, :weight_in_gram, :integer, default: 0, null: false
  end
end
