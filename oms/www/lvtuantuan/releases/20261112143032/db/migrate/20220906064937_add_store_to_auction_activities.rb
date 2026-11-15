# frozen_string_literal: true

class AddStoreToAuctionActivities < ActiveRecord::Migration[5.2]
  def change
    add_reference :auction_activities, :store, foreign_key: true
  end
end
