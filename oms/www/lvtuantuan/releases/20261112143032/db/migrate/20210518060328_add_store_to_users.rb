# frozen_string_literal: true

class AddStoreToUsers < ActiveRecord::Migration[5.2]
  def change
    add_reference :users, :selected_store, foreign_key: { to_table: "stores" }
    add_reference :push_messages, :store, foreign_key: true
  end
end
