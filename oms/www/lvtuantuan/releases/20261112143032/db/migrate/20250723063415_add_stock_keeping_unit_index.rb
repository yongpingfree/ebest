# frozen_string_literal: true
class AddStockKeepingUnitIndex < ActiveRecord::Migration[5.2]
  def change
    add_index :stock_keeping_units, [:id, :item_id]
  end
end
