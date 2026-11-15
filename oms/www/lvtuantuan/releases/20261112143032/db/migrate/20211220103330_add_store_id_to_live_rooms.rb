# frozen_string_literal: true

class AddStoreIdToLiveRooms < ActiveRecord::Migration[5.2]
  def change
    add_belongs_to :live_rooms, :store
  end
end
