# frozen_string_literal: true

class CreateAdminUserStores < ActiveRecord::Migration[5.2]
  def change
    create_table :admin_user_stores do |t|

      t.belongs_to :store
      t.belongs_to :admin_user
      t.timestamps
    end
  end
end
