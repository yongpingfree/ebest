class AddPoolColumnsToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :pool_coupon_template_ids, :integer, array: true
    add_column :orders, :pool_gifts_properties, :json
    add_column :orders, :active_pools, :json, default: {}
  end
end
