#frozen_string_literal: true

class CreateGroupons < ActiveRecord::Migration[5.2]
  def change
    create_table :groupons do |t|
      t.integer :status
      t.datetime :expired_at
      t.datetime :finished_at
      t.datetime :cancel_at
      t.belongs_to :creator
      t.belongs_to :groupon_activity
      t.belongs_to :sku_groupon

      t.timestamps
    end
  end
end
