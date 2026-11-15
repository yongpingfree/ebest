# frozen_string_literal: true

class CreateWebCustomListItems < ActiveRecord::Migration[5.2]
  def change
    create_table :web_custom_list_items do |t|
      t.references :web_custom_list, foreign_key: true
      t.references :item, foreign_key: true
      t.integer :position

      t.timestamps
    end
  end
end
