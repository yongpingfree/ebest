# frozen_string_literal: true

class AddRulesToGrouponActivities < ActiveRecord::Migration[5.2]
  def change
    add_column :groupon_activities, :rules, :text
  end
end
