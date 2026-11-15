# frozen_string_literal: true

class AddPendingInStockNoticesCountToStockKeepingUnits < ActiveRecord::Migration[5.2]
  def change
    add_column :stock_keeping_units, :pending_in_stock_notices_count, :integer, default: 0
  end
end
