# frozen_string_literal: true

class AddKindToPushMessages < ActiveRecord::Migration[5.2]
  def change
    add_column :push_messages, :kind, :integer, default: 0
  end
end
