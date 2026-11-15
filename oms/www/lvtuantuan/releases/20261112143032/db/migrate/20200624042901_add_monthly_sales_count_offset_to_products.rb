# frozen_string_literal: true

class AddMonthlySalesCountOffsetToProducts < ActiveRecord::Migration[5.2]
  def change
    add_column :products, :monthly_sales_count_offset, :integer, default: 0

    MagicBean::Product.reset_column_information

    MagicBean::Product.find_each do |product|
      product.monthly_sales_count_offset = product.item&.monthly_sales_count_offset
      product.save
    end
  end
end
