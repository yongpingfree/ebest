# frozen_string_literal: true

class CreateCustomLists < ActiveRecord::Migration[5.2]
  def change
    create_table :custom_lists do |t|
      t.integer :item_ids, array: true, default: []
      t.string :title
      t.string :remark

      t.timestamps
    end
  end
end
