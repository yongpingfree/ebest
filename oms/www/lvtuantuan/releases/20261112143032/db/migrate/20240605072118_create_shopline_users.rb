# frozen_string_literal: true

class CreateShoplineUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :shopline_users do |t|
      t.string :email
      t.string :password_digest
      t.string :phone

      t.timestamps
    end
  end
end
