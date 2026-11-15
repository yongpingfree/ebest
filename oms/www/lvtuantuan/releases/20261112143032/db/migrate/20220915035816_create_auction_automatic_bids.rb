# frozen_string_literal: true

class CreateAuctionAutomaticBids < ActiveRecord::Migration[5.2]
  def change
    create_table :auction_automatic_bids do |t|
      t.references :user, foreign_key: true
      t.references :auction_activity, foreign_key: true
      t.integer :amount_limit_in_cent, null: false

      t.timestamps
    end
  end
end
