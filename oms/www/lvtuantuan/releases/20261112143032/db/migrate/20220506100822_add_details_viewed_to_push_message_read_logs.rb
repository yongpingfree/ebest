# frozen_string_literal: true

class AddDetailsViewedToPushMessageReadLogs < ActiveRecord::Migration[5.2]
  def change
    add_column :push_message_read_logs, :details_viewed, :boolean, default: false
  end
end
