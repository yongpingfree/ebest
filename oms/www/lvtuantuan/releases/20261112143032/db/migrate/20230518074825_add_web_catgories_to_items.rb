# frozen_string_literal: true

class AddWebCatgoriesToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :web_category_id, :integer
    add_column :items, :parent_web_category_id, :integer
    add_column :items, :minor_web_category_id, :integer

    add_index :items, :web_category_id
    add_index :items, :parent_web_category_id
    add_index :items, :minor_web_category_id
  end
end
