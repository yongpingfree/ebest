class AddPaymentInProgressToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :payment_in_progress, :boolean, default: false
  end
end
