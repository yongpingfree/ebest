# frozen_string_literal: true

class AddNewUserPriceToOrderItems < ActiveRecord::Migration[5.2]
  def change
    add_column :order_items, :is_new_user_price, :boolean, default: false
  end
end
