# frozen_string_literal: true

class ChangeWeekdayFromCutoffTimes < ActiveRecord::Migration[5.2]
  def change
    remove_column :cutoff_times, :weekday
    add_column :cutoff_times, :weekdays, :string, array: true, default: []
  end
end
