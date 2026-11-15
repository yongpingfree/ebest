# frozen_string_literal: true
class AddSyncedFromFreshAtToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :synce_from_fresh_at, :datetime
  end
end
