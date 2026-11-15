# frozen_string_literal: true

class CreatePagePopups < ActiveRecord::Migration[5.2]
  def change
    create_table :page_popups do |t|
      t.string :title
      t.string :image
      t.string :path
      t.boolean :for_new_user, default: false
      t.datetime :start_at
      t.datetime :end_at
      t.integer :position, default: 0


      t.timestamps
    end
  end
end
