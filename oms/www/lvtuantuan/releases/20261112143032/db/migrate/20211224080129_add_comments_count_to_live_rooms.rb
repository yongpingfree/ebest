# frozen_string_literal: true

class AddCommentsCountToLiveRooms < ActiveRecord::Migration[5.2]
  def change
    add_column :live_rooms, :actual_comments_count, :integer, default: 0, comment: "实际评论数"
    add_column :live_rooms, :actual_comment_users_count, :integer, default: 0, comment: "实际评论人数"
  end
end
