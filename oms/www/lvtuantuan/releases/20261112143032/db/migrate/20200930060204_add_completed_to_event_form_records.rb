# frozen_string_literal: true

class AddCompletedToEventFormRecords < ActiveRecord::Migration[5.2]
  def change
    add_column :event_form_records, :completed_at, :datetime
  end
end
