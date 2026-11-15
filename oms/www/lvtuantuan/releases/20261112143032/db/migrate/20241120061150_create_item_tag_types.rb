# frozen_string_literal: true

class CreateItemTagTypes < ActiveRecord::Migration[5.2]
  def change
    create_table :item_tag_types do |t|
      t.string :name, comment: "类型名称"
      t.timestamps
    end
  end
end
