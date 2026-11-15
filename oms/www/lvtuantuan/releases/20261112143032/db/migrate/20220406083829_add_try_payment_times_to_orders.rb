# frozen_string_literal: true

class AddTryPaymentTimesToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :try_payment_times, :integer, comment: "用户尝试支付次数（只记信用卡支付）"
  end
end
