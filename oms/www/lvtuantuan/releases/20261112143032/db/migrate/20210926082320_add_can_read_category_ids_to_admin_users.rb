# frozen_string_literal: true

class AddCanReadCategoryIdsToAdminUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :admin_users, :can_read_category_ids, :integer, default: [], array: true
  end
end
