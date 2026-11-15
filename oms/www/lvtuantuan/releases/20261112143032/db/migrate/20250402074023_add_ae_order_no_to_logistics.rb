# frozen_string_literal: true

class AddAeOrderNoToLogistics < ActiveRecord::Migration[5.2]
  def change
    add_column :logistics, :ae_order_no, :string, comment: "AE 订单号"
  end
end
