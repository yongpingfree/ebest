# frozen_string_literal: true
class AddChildrenToStockKeepingUnitsAndOrderItems < ActiveRecord::Migration[5.2]
  def change
    add_column :stock_keeping_units, :children, :json, default: []
    add_column :order_items, :children, :json, default: []
    add_column :order_items, :sku_type, :integer, default: 1
  end
end
