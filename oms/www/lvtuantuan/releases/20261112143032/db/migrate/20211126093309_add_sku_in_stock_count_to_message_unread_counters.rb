# frozen_string_literal: true

class AddSkuInStockCountToMessageUnreadCounters < ActiveRecord::Migration[5.2]
  def change
    add_column :message_unread_counters, :sku_in_stock_count, :integer, default: 0
  end
end
