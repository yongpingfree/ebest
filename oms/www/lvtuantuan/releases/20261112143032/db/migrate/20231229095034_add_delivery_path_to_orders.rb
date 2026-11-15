# frozen_string_literal: true

class AddDeliveryPathToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :delivery_path, :string, comment: "配送路线"
  end
end
