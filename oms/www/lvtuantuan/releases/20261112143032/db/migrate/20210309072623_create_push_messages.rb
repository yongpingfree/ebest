# frozen_string_literal: true

class CreatePushMessages < ActiveRecord::Migration[5.2]
  def change
    create_table :push_messages do |t|
      t.belongs_to :admin_user, foreign_key: true
      t.string :title
      t.text :content
      t.integer :state, default: 0
      t.datetime :push_at
      t.integer :uv, default: 0
      t.integer :pv, default: 0

      t.timestamps
    end
  end
end
