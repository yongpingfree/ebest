# frozen_string_literal: true

class AddEmailConfimationAttrsToMembers < ActiveRecord::Migration[5.2]
  def change
    add_column :members, :email_confirmation_token, :string
    add_index :members, :email_confirmation_token, unique: true
  end
end
