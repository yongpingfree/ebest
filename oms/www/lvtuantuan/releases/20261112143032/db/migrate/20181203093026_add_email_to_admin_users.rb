# frozen_string_literal: true

class AddEmailToAdminUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :admin_users, :email, :string
  end
end
