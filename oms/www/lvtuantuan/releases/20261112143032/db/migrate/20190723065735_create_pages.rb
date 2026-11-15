# frozen_string_literal: true

class CreatePages < ActiveRecord::Migration[5.2]
  def change
    create_table :pages do |t|
      t.string :name
      t.integer :kind
      t.text :content

      t.timestamps
    end
  end
end
