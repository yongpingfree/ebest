# frozen_string_literal: true

class AddHighlightedSkuIdToLiveRooms < ActiveRecord::Migration[5.2]
  def change
    add_reference :live_rooms, :highlighted_sku, foreign_key: { to_table: :stock_keeping_units }
  end
end
