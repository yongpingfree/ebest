# frozen_string_literal: true

module InventoryConcern
  extend ActiveSupport::Concern

  def increase_inventory!(custom_quantity = nil)
    stock_keeping_unit.increase_inventory!(custom_quantity || quantity)
  end

  def decrease_inventory!
    stock_keeping_unit.decrease_inventory!(quantity)
  end

  # increment!不会触发item的before_save
  def increase_sales_count!
    item = stock_keeping_unit.item
    item.update(sales_count: item.sales_count + quantity)
  end

  def decrease_sales_count!
    item = stock_keeping_unit.item
    item.update(sales_count: item.sales_count - quantity)
  end
end
