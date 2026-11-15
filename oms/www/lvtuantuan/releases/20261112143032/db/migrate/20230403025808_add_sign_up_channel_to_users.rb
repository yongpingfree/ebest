# frozen_string_literal: true

class AddSignUpChannelToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :sign_up_channel, :integer, default: 2
  end
end
