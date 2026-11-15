# frozen_string_literal: true

class AddReceiveNotifyEmailToAdminUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :admin_users, :receive_notify_email, :boolean, default: false
  end
end
