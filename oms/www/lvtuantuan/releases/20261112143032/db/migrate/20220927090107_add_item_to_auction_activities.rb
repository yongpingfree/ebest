# frozen_string_literal: true

class AddItemToAuctionActivities < ActiveRecord::Migration[5.2]
  def change
    add_reference :auction_activities, :item, foreign_key: true
    add_reference :auction_activities, :stock_keeping_unit, foreign_key: true
    add_column :auction_activities, :no, :string, null: false
    add_index :auction_activities, :no, unique: true
  end
end
