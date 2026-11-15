# frozen_string_literal: true

class AddNewColumnsToGrouponActivities < ActiveRecord::Migration[5.2]
  def change
    add_column :groupon_activities, :type, :string, default: "MagicBean::NormalGrouponActivity"
    add_column :groupon_activities, :wms_sync_type, :integer, default: 1
  end
end
