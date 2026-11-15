# frozen_string_literal: true
class AddBranchIoColumnsToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :branch_io_campaign, :string
    add_column :users, :branch_io_channel, :string
    add_column :users, :branch_io_feature, :string
    add_column :users, :branch_io_extra_hash, :json
  end
end
