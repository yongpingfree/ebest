# frozen_string_literal: true

class AddOriginalAmountInCentToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :original_payment_in_cent, :integer
  end
end
