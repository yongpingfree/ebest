# frozen_string_literal: true

class AddAfterSalesCountToOrder < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :after_sales_count, :integer, default: 0

    MagicBean::Order.ids.each do |id|
      MagicBean::Order.reset_counters(id, :after_sales)
    end
  end
end
