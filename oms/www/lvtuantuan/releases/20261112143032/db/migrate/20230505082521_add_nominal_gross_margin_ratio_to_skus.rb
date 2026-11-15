# frozen_string_literal: true

class AddNominalGrossMarginRatioToSkus < ActiveRecord::Migration[5.2]
  def change
    add_column :stock_keeping_units, :nominal_gross_margin_ratio, :decimal, precision: 12, scale: 2, default: 0, comment: "名义毛利率"
  end
end
