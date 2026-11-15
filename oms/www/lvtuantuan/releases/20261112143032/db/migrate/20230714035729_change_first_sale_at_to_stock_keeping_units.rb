# frozen_string_literal: true

class ChangeFirstSaleAtToStockKeepingUnits < ActiveRecord::Migration[5.2]
  def change
    remove_column :items, :first_sale_at, type: :datetime
    add_column :stock_keeping_units, :first_sale_at, :datetime, comment: "首次上架开卖时间"
  end
end
