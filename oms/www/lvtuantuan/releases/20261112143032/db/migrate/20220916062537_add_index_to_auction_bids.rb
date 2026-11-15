# frozen_string_literal: true

class AddIndexToAuctionBids < ActiveRecord::Migration[5.2]
  def change
    add_index :auction_bids, [:auction_activity_id, :amount_in_cent], unique: true
    add_index :auction_automatic_bids, [:auction_activity_id, :amount_limit_in_cent], unique: true, name: "index_automatic_bids_on_auction_activity_id_and_amount_limit"
  end
end
