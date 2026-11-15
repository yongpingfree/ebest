# frozen_string_literal: true

class CreateCutoffTimes < ActiveRecord::Migration[5.2]
  def change
    create_table :cutoff_times do |t|

      t.string :weekday
      t.string :time_at, array: true, default: []
      t.belongs_to :item

      t.timestamps
    end
  end
end
