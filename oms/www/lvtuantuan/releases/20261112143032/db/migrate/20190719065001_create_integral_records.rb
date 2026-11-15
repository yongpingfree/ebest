# frozen_string_literal: true

class CreateIntegralRecords < ActiveRecord::Migration[5.2]
  def change
    create_table :integral_records do |t|
      t.integer :available_integral
      t.integer :blocked_integral
      t.integer :integral
      t.integer :kind
      t.belongs_to :member, foreign_key: true
      t.belongs_to :targetable, polymorphic: true

      t.timestamps
    end
  end
end
