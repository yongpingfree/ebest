# frozen_string_literal: true

class AddExpiredHoursToGrouponActivities < ActiveRecord::Migration[5.2]
  def change
    add_column :groupon_activities, :is_real, :boolean, default: false
    add_column :groupon_activities, :expired_hours, :integer, default: 0

    say_with_time "init_old_activities_expired_hours" do
      MagicBean::GrouponActivity.reset_column_information

      MagicBean::GrouponActivity.update_all expired_hours: 24
    end
  end
end
