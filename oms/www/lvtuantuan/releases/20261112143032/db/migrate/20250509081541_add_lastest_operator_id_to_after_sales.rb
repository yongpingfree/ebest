# frozen_string_literal: true

class AddLastestOperatorIdToAfterSales < ActiveRecord::Migration[5.2]
  def change
    add_column :after_sales, :lastest_operator_id, :bigint
    add_index :after_sales, :lastest_operator_id
  end
end
