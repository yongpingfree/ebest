# frozen_string_literal: true

class AddIsChildToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :is_child, :boolean, default: false, comment: "是否加单的子单"
  end
end
