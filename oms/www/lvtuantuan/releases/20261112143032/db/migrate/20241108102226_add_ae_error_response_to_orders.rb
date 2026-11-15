# frozen_string_literal: true

class AddAeErrorResponseToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :ae_error_response, :jsonb
    add_column :orders, :ae_order_list, :string, array: true
  end
end
