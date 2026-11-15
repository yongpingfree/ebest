# frozen_string_literal: true

class CreateAdminUser < ActiveRecord::Migration[5.2]
  def change
    create_table :admin_users do |t|
      t.string :name
      t.string :mobile, index: true
      t.integer :state, default: 1
      t.integer :role, default: 1
      t.references :creator, foreign_key: {to_table: :admin_users}

      t.timestamps
    end
  end
end
