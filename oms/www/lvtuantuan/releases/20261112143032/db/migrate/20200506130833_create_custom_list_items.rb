# frozen_string_literal: true

class CreateCustomListItems < ActiveRecord::Migration[5.2]
  def up
    add_column :custom_lists, :tmp_item_ids, :integer, array: true

    execute("UPDATE custom_lists SET tmp_item_ids=(SELECT item_ids FROM custom_lists as custom_lists_b WHERE custom_lists.id=custom_lists_b.id);")

    create_table :custom_list_items do |t|
      t.integer :position
      t.belongs_to :item
      t.belongs_to :custom_list

      t.timestamps
    end
    add_index :custom_list_items, [:item_id, :custom_list_id], unique: true

    MagicBean::CustomList.reset_column_information
    MagicBean::CustomList.find_each do |custom_list|
      custom_list.tmp_item_ids.each.with_index do |item_id, index|
        custom_list.custom_list_items.create(item_id: item_id, position: index)
      end
    end

    remove_column :custom_lists, :tmp_item_ids, :integer, array: true
  end

  def down
    drop_table :custom_list_items do |t|
      t.integer :position
      t.belongs_to :item
      t.belongs_to :custom_list
    end
  end
end
