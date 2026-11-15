# frozen_string_literal: true
class AddDeletedByUserAtToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :deleted_by_user_at, :datetime
    add_index :orders, :deleted_by_user_at
  end
end
