# frozen_string_literal: true

class CreateOperationRecords < ActiveRecord::Migration[5.2]
  def change
    create_table :operation_records do |t|

      t.belongs_to :admin_user
      t.belongs_to :operatable, polymorphic: true
      t.text :content
      t.timestamps
    end
  end
end
