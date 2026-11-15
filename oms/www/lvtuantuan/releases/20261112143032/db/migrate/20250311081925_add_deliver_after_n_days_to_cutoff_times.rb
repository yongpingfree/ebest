# frozen_string_literal: true

class AddDeliverAfterNDaysToCutoffTimes < ActiveRecord::Migration[5.2]
  def change
    add_column :cutoff_times, :deliver_after_n_days, :integer, default: 2, comment: "默认接单后2天发货"
  end
end
