# frozen_string_literal: true

class AddGrouponActivityIdToOrders < ActiveRecord::Migration[5.2]
  def up
    add_belongs_to :orders, :groupon_activity
    add_belongs_to :orders, :sku_groupon
    remove_column :orders, :order_type
    add_column :orders, :type, :string
  end

  def down
    remove_column :orders, :type
    add_column :orders, :order_type, :integer, default: 1
    remove_belongs_to :orders, :groupon_activity
    remove_belongs_to :orders, :sku_groupon
  end
end
