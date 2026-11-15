# frozen_string_literal: true

class AddChannelToOperationRecords < ActiveRecord::Migration[5.2]
  def change
    add_column :operation_records, :channel, :integer, default: 1
  end
end
