# frozen_string_literal: true

class CreateSubscribeRecords < ActiveRecord::Migration[5.2]
  def change
    create_table :subscribe_records do |t|
      t.belongs_to :targetable, polymorphic: true
      t.string :template_id
      t.belongs_to :user

      t.timestamps
    end
  end
end
