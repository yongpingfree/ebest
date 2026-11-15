# frozen_string_literal: true

class AddTurnoverRateToSkus < ActiveRecord::Migration[5.2]
  def change
    add_column :stock_keeping_units, :turnover_rate, :decimal, precision: 12, scale: 2, comment: "周转率"
  end
end
