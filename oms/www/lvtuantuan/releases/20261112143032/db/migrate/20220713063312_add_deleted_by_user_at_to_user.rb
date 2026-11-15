# frozen_string_literal: true

class AddDeletedByUserAtToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :deleted_by_user_at, :datetime
  end
end
