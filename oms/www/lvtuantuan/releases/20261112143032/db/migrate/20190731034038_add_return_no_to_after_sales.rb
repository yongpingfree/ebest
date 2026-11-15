# frozen_string_literal: true

class AddReturnNoToAfterSales < ActiveRecord::Migration[5.2]
  def change
    add_column :after_sales, :return_no, :string, comment: "erp退换货单号"
  end
end
