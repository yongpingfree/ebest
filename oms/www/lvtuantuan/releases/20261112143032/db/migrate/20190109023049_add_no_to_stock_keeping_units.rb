# frozen_string_literal: true

class AddNoToStockKeepingUnits < ActiveRecord::Migration[5.2]
  def change
    add_column :stock_keeping_units, :no, :string
  end
end
