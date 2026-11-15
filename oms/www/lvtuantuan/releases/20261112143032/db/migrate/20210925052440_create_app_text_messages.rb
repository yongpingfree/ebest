# frozen_string_literal: true

class CreateAppTextMessages < ActiveRecord::Migration[5.2]
  def change
    create_table :app_text_messages do |t|
      t.string :title, null: false
      t.string :content, null: false
      t.datetime :read_at
      t.integer :kind, null: false
      t.references :user, foreign_key: true
      t.references :admin_user, foreign_key: true

      t.timestamps
    end
  end
end
