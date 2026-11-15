# frozen_string_literal: true

class AddResetPhoneTokenToShoplineUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :shopline_users, :reset_phone_token, :string
  end
end
