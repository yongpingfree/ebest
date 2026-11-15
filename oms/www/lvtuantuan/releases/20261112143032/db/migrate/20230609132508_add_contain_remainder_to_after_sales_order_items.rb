# frozen_string_literal: true

class AddContainRemainderToAfterSalesOrderItems < ActiveRecord::Migration[5.2]
  def change
    add_column :after_sales_order_items, :contain_remainder, :boolean, default: false, comment: "退款各项金额是否包含余数"
  end
end
