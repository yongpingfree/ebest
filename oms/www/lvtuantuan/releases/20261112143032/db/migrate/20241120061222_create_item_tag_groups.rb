class CreateItemTagGroups < ActiveRecord::Migration[5.2]
  def change
    create_table :item_tag_groups do |t|
      t.belongs_to :item_tag_type
      
      t.timestamps
    end

    reversible do |dir|
      dir.up do
        MagicBean::ItemTagGroup.create_translation_table! name: :string
      end

      dir.down do
        MagicBean::ItemTagGroup.drop_translation_table!
      end
    end
  end
end
