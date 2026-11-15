# frozen_string_literal: true

class CreateUsersPushMessages < ActiveRecord::Migration[5.2]
  def change
    create_table :users_push_messages do |t|
      t.belongs_to :push_message, foreign_key: true
      t.belongs_to :user, foreign_key: true

      t.timestamps
    end
  end
end
