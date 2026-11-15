# frozen_string_literal: true

class AddProvinceToOrders < ActiveRecord::Migration[5.2]
  def change
    add_reference :orders, :province, foreign_key: true
  end
end
