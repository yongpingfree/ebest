# frozen_string_literal: true

class AddNewColumnsToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :password_digest, :string
    add_column :users, :all_info_finished, :boolean, default: false
  end
end
