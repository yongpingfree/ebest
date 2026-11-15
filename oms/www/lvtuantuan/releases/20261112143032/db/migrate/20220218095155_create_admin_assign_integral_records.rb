# frozen_string_literal: true

class CreateAdminAssignIntegralRecords < ActiveRecord::Migration[5.2]
  def change
    create_table :admin_assign_integral_records do |t|

      t.belongs_to :admin_user
      t.belongs_to :member
      t.belongs_to :store
      t.text :content
      t.timestamps
    end
  end
end
