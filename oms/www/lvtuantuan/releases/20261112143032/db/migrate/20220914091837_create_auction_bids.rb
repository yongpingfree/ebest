# frozen_string_literal: true

class CreateAuctionBids < ActiveRecord::Migration[5.2]
  def change
    create_table :auction_bids do |t|
      t.integer :kind, default: 0, null: false
      t.references :user, foreign_key: true
      t.references :auction_activity, foreign_key: true
      t.references :member, foreign_key: true
      t.integer :amount_in_cent, null: false

      t.timestamps
    end
  end
end
