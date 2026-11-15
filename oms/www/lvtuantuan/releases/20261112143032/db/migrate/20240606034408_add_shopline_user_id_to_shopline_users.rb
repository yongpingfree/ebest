# frozen_string_literal: true

class AddShoplineUserIdToShoplineUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :shopline_users, :shopline_user_id, :string
    add_column :shopline_users, :addresses, :jsonb
  end
end
