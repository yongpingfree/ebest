# frozen_string_literal: true

class AddBidAttrsToAuctionActivities < ActiveRecord::Migration[5.2]
  def change
    add_reference :auction_activities, :best_bid, foreign_key: { to_table: :auction_bids  }
    add_column :auction_activities, :best_bid_amount_in_cent, :integer
    add_column :auction_activities, :bids_count, :integer, default: 0
    add_column :auction_activities, :automatic_bids_count, :integer, default: 0
  end
end
