# frozen_string_literal: true

class AddDisplayPriceToOrderItems < ActiveRecord::Migration[5.2]
  def change
    add_column :order_items, :display_price_in_cent, :integer, default: 0
  end
end
