# frozen_string_literal: true

class AddStatisticsToLiveRooms < ActiveRecord::Migration[5.2]
  def change
    add_column :live_rooms, :actual_viewed_count, :integer, default: 0, comment: "实际观看次数"
    add_column :live_rooms, :viewed_count_offset, :integer, default: 0, comment: "基础观看次数"
    add_column :live_rooms, :viewed_count_multiplier, :integer, default: 1, comment: "实际观看次数乘数"
    add_column :live_rooms, :actual_liked_count, :integer, default: 0, comment: "实际点赞次数"
    add_column :live_rooms, :liked_count_offset, :integer, default: 0, comment: "基础点赞次数"
    add_column :live_rooms, :liked_count_multiplier, :integer, default: 1, comment: "实际点赞次数乘数"
    add_column :live_rooms, :actual_peak_concurrent_users_count, :integer, default: 0, comment: "实际峰值在线人数"
    add_column :live_rooms, :actual_viewed_users_count, :integer, default: 0, comment: "实际观看人数"
    add_column :live_rooms, :actual_liked_users_count, :integer, default: 0, comment: "实际点赞人数"
    add_column :live_rooms, :average_user_viewed_time_in_sec, :integer, default: 0, comment: "平均观看时长"
  end
end
