# frozen_string_literal: true

class CreatePushMessageReadLogs < ActiveRecord::Migration[5.2]
  def change
    create_table :push_message_read_logs do |t|
      t.belongs_to :user, foreign_key: true
      t.belongs_to :push_message, foreign_key: true

      t.timestamps
    end

    add_index :push_message_read_logs, [:user_id, :push_message_id], unique: true
  end
end
