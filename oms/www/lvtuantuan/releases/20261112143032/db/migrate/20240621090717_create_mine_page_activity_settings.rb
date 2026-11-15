# frozen_string_literal: true
class CreateMinePageActivitySettings < ActiveRecord::Migration[5.2]
  def change
    create_table :mine_page_activity_settings do |t|
      t.string :name, comment: "活动名称"
      t.string :icon, comment: "活动图标"
      t.belongs_to :custom_page
      t.belongs_to :store
      t.integer :position, comment: "排序", default: 999
      t.boolean :enabled, comment: "是否启用", default: true

      t.timestamps
    end
  end
end
