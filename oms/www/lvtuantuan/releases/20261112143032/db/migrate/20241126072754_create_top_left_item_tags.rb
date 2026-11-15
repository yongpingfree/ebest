# frozen_string_literal: true
class CreateTopLeftItemTags < ActiveRecord::Migration[5.2]
  def change
    create_table :top_left_item_tags do |t|

      t.string :name
      t.string :icon
      t.integer :item_ids, array: true, default: []
      t.datetime :start_at
      t.datetime :end_at
      t.belongs_to :store
      
      t.timestamps
    end
  end
end
