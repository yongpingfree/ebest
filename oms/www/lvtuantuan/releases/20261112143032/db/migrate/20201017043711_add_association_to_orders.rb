# frozen_string_literal: true

class AddAssociationToOrders < ActiveRecord::Migration[5.2]
  def change
    add_belongs_to :orders, :gift_card_coupon, foreign_key: true
    add_column :orders, :gift_card_amount_in_cent, :integer, default: 0
  end
end
