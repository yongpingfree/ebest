# frozen_string_literal: true

class CreateReportPages < ActiveRecord::Migration[5.2]
  def change
    create_table :report_pages do |t|
      t.string :name, null: false
      t.text :content, null: false
      t.integer :creator_id, null: false
      t.integer :admin_user_ids, array: true, default: [], comment: "可查看的管理员用户"
      t.timestamps

      t.index :creator_id
    end
  end
end
