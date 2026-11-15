# frozen_string_literal: true

class CreateRoleTemplates < ActiveRecord::Migration[5.2]
  def change
    create_table :role_templates do |t|

      t.string :name
      t.string :permissions, default: [], array: true
      t.timestamps
    end
  end
end
