# frozen_string_literal: true

class AddSalesCountOffsetToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :sales_count_offset, :integer, default: 0
    add_column :products, :sales_count_offset, :integer, default: 0
  end
end
