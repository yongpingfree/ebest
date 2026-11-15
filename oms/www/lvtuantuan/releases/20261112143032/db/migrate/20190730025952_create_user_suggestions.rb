# frozen_string_literal: true

class CreateUserSuggestions < ActiveRecord::Migration[5.2]
  def change
    create_table :user_suggestions do |t|
      t.text :content
      t.integer :status, default: 1
      t.references :user

      t.timestamps
    end
  end
end
