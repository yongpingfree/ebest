# frozen_string_literal: true

class AddSyncedAtToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :synced_at, :datetime
  end
end
