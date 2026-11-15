# frozen_string_literal: true

class AddPoolPriceInCentToOrderItems < ActiveRecord::Migration[5.2]
  def change
    add_column :order_items, :pool_price_in_cent, :integer
  end
end
