# frozen_string_literal: true

class AddResetPasswordTokenToShoplineUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :shopline_users, :reset_password_token, :string
  end
end
