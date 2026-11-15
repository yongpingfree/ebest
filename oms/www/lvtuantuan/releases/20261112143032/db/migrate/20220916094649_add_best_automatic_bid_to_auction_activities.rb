# frozen_string_literal: true

class AddBestAutomaticBidToAuctionActivities < ActiveRecord::Migration[5.2]
  def change
    add_reference :auction_activities, :best_automatic_bid, foreign_key: { to_table: :auction_automatic_bids  }
  end
end
