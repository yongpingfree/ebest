# frozen_string_literal: true

class CreateComments < ActiveRecord::Migration[5.2]
  def change
    create_table :comments do |t|
      t.string :content
      t.string :pictures, array: true
      t.string :commentable_type
      t.integer :commentable_id
      t.references :user
      t.references :item

      t.timestamps
    end

    add_index :comments, [:commentable_type, :commentable_id]
  end
end
