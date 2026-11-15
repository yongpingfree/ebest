# frozen_string_literal: true

class CreatePromoStockKeepingUnits < ActiveRecord::Migration[5.2]
  def change
    create_table :promo_stock_keeping_units do |t|
      t.belongs_to :promo_code_template
      t.belongs_to :stock_keeping_unit
      t.integer :price_in_cent, comment: "SKU 单价"
      t.integer :quantity, comment: "SKU 数量"

      t.timestamps
    end
  end
end
