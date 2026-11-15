# frozen_string_literal: true

class AddDeletedAtToOperationRecords < ActiveRecord::Migration[5.2]
  def change
    add_column :operation_records, :deleted_at, :datetime
  end
end
