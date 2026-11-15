# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :users do |t|
      t.string :nickname
      t.string :avatar
      t.string :mobile
      t.string :open_id
      t.integer :gender

      t.timestamps
    end
  end
end
