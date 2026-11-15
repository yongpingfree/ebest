# frozen_string_literal: true

class AddCanCoverWeeksToStockKeepingUnits < ActiveRecord::Migration[5.2]
  def change
    add_column :stock_keeping_units, :can_cover_weeks, :integer
  end
end
