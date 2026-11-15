# frozen_string_literal: true

class AddEbestPlatformUnionidToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :ebest_platform_unionid, :string
    add_column :users, :deleted_mini_open_id, :string
    add_index :users, :ebest_platform_unionid, unique: true
  end
end
