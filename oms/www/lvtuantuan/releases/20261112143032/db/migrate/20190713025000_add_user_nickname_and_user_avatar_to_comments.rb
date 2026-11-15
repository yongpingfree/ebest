# frozen_string_literal: true

class AddUserNicknameAndUserAvatarToComments < ActiveRecord::Migration[5.2]
  def change
    add_column :comments, :user_nickname, :string
    add_column :comments, :user_avatar, :string
  end
end
