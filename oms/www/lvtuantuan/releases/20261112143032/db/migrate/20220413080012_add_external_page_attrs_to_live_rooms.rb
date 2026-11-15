# frozen_string_literal: true

class AddExternalPageAttrsToLiveRooms < ActiveRecord::Migration[5.2]
  def change
    add_column :live_rooms, :custom_page_icon, :string
    add_reference :live_rooms, :custom_page
  end
end
