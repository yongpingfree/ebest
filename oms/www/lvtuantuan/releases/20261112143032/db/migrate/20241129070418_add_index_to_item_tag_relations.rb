# 添加item_tag_relations表的索引

class AddIndexToItemTagRelations < ActiveRecord::Migration[5.2]
  def change
    add_index :item_tag_relations, :allow_view_same_tag_items
  end
end
