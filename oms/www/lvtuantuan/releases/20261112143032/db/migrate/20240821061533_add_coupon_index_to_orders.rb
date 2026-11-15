class AddCouponIndexToOrders < ActiveRecord::Migration[5.2]
  def change
    remove_index :orders, :coupon_id
    add_index :orders, :coupon_id, unique: true, where: "status <> 6" # status为trade_closed不校验唯一性
  end
end
