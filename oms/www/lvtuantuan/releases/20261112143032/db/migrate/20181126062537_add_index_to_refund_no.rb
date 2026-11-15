# frozen_string_literal: true

class AddIndexToRefundNo < ActiveRecord::Migration[5.2]
  def change
    add_index :after_sales, :refund_no, unique: true
  end
end
