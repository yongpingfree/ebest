# frozen_string_literal: true
class CreateHotSearches < ActiveRecord::Migration[5.2]
  def change
    create_table :hot_searches do |t|
      t.string :word, null: false
      t.integer :position, null: false
      t.references :store, foreign_key: true
      t.boolean :show, default: false

      t.timestamps
    end
  end
end
