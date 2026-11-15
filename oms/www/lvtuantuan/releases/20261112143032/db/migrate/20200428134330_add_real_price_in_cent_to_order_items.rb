# frozen_string_literal: true

class AddRealPriceInCentToOrderItems < ActiveRecord::Migration[5.2]
  def change
    add_column :order_items, :real_price_in_cent, :integer
  end
end
