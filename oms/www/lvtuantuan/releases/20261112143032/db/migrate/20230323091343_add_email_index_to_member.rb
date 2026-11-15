# frozen_string_literal: true

class AddEmailIndexToMember < ActiveRecord::Migration[5.2]
  def change
    add_index :members, :email
  end
end
