# frozen_string_literal: true

class CreateOrders < ActiveRecord::Migration[5.2]
  def change
    create_table :orders do |t|
      t.string :no
      t.integer :payment_in_cent, default: 0
      t.integer :status, default: 1
      t.integer :amount_in_cent, default: 0
      t.datetime :paid_at
      t.hstore :receiver_properties, comment: "收件人信息"
      t.string :transaction_id, comment: "外部支付单号"
      t.datetime :finished_at, comment: "订单完成时间，通过计算判断是否可售后"
      t.string :buyer_message
      t.string :refund_no
      t.string :prepay_id
      t.string :cancel_reason
      t.integer :actually_amount_in_cent, default: 0, comment: "订单实际金额，去除部分退款之后实际金额"
      t.references :user

      t.timestamps
    end

    add_index :orders, :no, unique: true
    add_index :orders, :refund_no, unique: true
  end
end
