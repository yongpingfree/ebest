# frozen_string_literal: true

class AddUserIdsToPushMessages < ActiveRecord::Migration[5.2]
  def change
    add_column :push_messages, :user_ids, :integer, array: true, default: []
  end
end
