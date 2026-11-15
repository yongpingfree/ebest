# frozen_string_literal: true

class CreateLiveComments < ActiveRecord::Migration[5.2]
  def change
    create_table :live_comments do |t|

      t.belongs_to :live_room
      t.belongs_to :user
      t.string :nickname
      t.string :device_id
      t.string :user_ip
      t.text :content
      t.datetime :commented_at
      t.timestamps
    end
  end
end
