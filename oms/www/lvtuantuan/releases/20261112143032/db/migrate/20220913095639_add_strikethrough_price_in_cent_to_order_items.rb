# frozen_string_literal: true

class AddStrikethroughPriceInCentToOrderItems < ActiveRecord::Migration[5.2]
  def change
    add_column :order_items, :strikethrough_price_in_cent, :integer
    add_column :order_items, :strikethrough_amount_in_cent, :integer
    add_column :orders, :strikethrough_amount_in_cent, :integer
  end
end
