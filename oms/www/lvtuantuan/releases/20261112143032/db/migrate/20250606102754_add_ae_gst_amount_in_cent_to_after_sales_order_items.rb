# frozen_string_literal: true

class AddAeGstAmountInCentToAfterSalesOrderItems < ActiveRecord::Migration[5.2]
  def change
    add_column :after_sales_order_items, :ae_gst_amount_in_cent, :integer, default: 0
    add_column :after_sales_order_items, :max_ae_gst_amount_in_cent, :integer, default: 0
  end
end
