# frozen_string_literal: true

class CreateSkuInStockNotices < ActiveRecord::Migration[5.2]
  def change
    create_table :sku_in_stock_notices do |t|
      t.belongs_to :user, foreign_key: true
      t.belongs_to :stock_keeping_unit, foreign_key: true
      t.integer :state, default: 0

      t.timestamps
    end
  end
end
