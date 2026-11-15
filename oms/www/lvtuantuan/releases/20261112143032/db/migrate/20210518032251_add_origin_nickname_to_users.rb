# frozen_string_literal: true

class AddOriginNicknameToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :origin_nickname, :string
    add_column :users, :origin_gender, :integer
    add_column :users, :origin_avatar, :string
  end
end
