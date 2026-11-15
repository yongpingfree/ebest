# frozen_string_literal: true

class AddEmailVerifiedAtToMembers < ActiveRecord::Migration[5.2]
  def change
    add_column :members, :email_verified_at, :datetime
  end
end
