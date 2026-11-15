# frozen_string_literal: true

class AddLockAttrsToAdminUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :admin_users, :failed_attempts, :integer, default: 0
    add_column :admin_users, :locked_at, :datetime
  end
end
