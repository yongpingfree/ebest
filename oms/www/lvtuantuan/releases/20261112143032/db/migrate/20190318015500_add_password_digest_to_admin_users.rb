# frozen_string_literal: true

class AddPasswordDigestToAdminUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :admin_users, :password_digest, :string
  end
end
