# frozen_string_literal: true

class AddOmipayPlatformToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :omipay_platform, :string
    add_column :payments, :platform, :string
  end
end
