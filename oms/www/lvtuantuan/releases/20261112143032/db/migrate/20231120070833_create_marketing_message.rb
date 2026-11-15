# frozen_string_literal: true

class CreateMarketingMessage < ActiveRecord::Migration[5.2]
  def change
    create_table :marketing_messages do |t|

      t.string :content
      t.belongs_to :store
      t.belongs_to :admin_user
      t.integer :state, default: 1, comment: "draft: 0, pending: 1, pushed: 2"
      t.integer :user_ids, array: true, default: [], comment: "指定用户"
      t.datetime :push_at
      t.timestamps
    end
  end
end
