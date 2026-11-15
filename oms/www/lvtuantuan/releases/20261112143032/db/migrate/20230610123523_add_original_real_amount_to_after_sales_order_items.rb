# frozen_string_literal: true

class AddOriginalRealAmountToAfterSalesOrderItems < ActiveRecord::Migration[5.2]
  def change
    add_column :after_sales_order_items, :original_real_amount_in_cent, :integer, default: 0, comment: "最初的优惠金额"

    say_with_time "init after_sales_order_items original_real_amount_in_cent" do
      MagicBean::AfterSalesOrderItem.reset_column_information
      MagicBean::AfterSalesOrderItem.update_all("original_real_amount_in_cent = real_amount_in_cent")
    end
  end
end
