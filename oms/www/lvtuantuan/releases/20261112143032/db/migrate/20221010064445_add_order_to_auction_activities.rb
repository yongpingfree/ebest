# frozen_string_literal: true

class AddOrderToAuctionActivities < ActiveRecord::Migration[5.2]
  def change
    add_reference :auction_activities, :order, foreign_key: true
  end
end
