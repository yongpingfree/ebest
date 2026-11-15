# frozen_string_literal: true

class RenameChildrenToStockKeepingUnits < ActiveRecord::Migration[5.2]
  def change
    rename_column :stock_keeping_units, :children, :groups
  end
end
