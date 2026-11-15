# frozen_string_literal: true

class AddBrandAndQaToAuctionActivities < ActiveRecord::Migration[5.2]
  def change
    add_reference :auction_activities, :brand, foreign_key: true
    add_reference :auction_activities, :qa_and_guarantee, foreign_key: true
  end
end
