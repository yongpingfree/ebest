# frozen_string_literal: true

class AddAppVersionToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :app_version, :string
  end
end
