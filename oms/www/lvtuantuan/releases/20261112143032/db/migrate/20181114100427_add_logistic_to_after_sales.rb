# frozen_string_literal: true

class AddLogisticToAfterSales < ActiveRecord::Migration[5.2]
  def change
    add_column :after_sales, :logistic_no, :string, index: true
    add_column :after_sales, :logistic_company, :string
  end
end
