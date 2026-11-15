# frozen_string_literal: true

class AddCustomPathToPushMessages < ActiveRecord::Migration[5.2]
  def change
    add_column :push_messages, :path_customized, :boolean, default: false
    add_column :push_messages, :path_customized_type, :string
    add_column :push_messages, :path_customized_id, :bigint
  end
end
