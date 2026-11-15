# frozen_string_literal: true

class AddResetEmailTokenToShoplineUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :shopline_users, :reset_email_token, :string
  end
end
