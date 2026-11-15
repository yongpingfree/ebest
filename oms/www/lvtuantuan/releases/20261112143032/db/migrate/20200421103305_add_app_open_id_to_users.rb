# frozen_string_literal: true

class AddAppOpenIdToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :app_open_id, :string
  end
end
