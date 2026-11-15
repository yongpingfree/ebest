# frozen_string_literal: true

class AddRefundsToThirdPartyOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :third_party_orders, :refunds, :jsonb
  end
end
