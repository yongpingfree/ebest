class AddSupayColumnsToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :supay_payment_dollar_in_cent, :integer, default: 0, comment: "Supay支付金额，单位：AUD"
    add_column :orders, :supay_payment_in_cent, :integer, default: 0, comment: "Supay支付金额，单位：CNY"
    add_column :orders, :supay_service_amount_dollar_in_cent, :integer, default: 0
    add_column :orders, :supay_platform, :string
  end
end
