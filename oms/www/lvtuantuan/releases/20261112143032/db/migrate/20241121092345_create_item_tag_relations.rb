class CreateItemTagRelations < ActiveRecord::Migration[5.2]
  def change
    create_table :item_tag_relations do |t|
      t.belongs_to :item
      t.belongs_to :item_tag
      t.boolean :allow_view_same_tag_items, default: false, comment: "是否允许查看同标签下的商品"

      t.timestamps
    end

    add_column :item_tags, :item_tag_relations_count, :integer, default: 0, comment: "打标签次数"
  end
end
