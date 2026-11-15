# frozen_string_literal: true
class AddPermissionsToAdminUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :admin_users, :permissions, :string, array: true, default: []
  end
end
