# frozen_string_literal: true
class AddWeekdaysAndTimePeriodToSelfPickUps < ActiveRecord::Migration[5.2]
  def change
    add_column :self_pick_ups, :weekdays, :string, array: true, default: []
    add_column :self_pick_ups, :time_period, :string, array: true, default: []
  end
end
