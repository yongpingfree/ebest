# frozen_string_literal: true

class AddAmountInCentToAfterSalesOrderItems < ActiveRecord::Migration[5.2]
  def change
    add_column :after_sales_order_items, :real_amount_in_cent, :integer, default: 0

    say_with_time "init_after_sale_order_item_amount_in_cent" do
      MagicBean::AfterSalesOrderItem.reset_column_information
      MagicBean::AfterSalesOrderItem.includes(:order_item).all.each do |item|
        item.set_real_amount_in_cent
        item.save(validate: false, touch: false)
      end
    end
  end
end
