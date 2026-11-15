# frozen_string_literal: true

class RenameLiveUserBlacklistsToMobileBlacklists < ActiveRecord::Migration[5.2]
  def change
    rename_table :live_room_user_blacklists, :mobile_blacklists
  end
end
