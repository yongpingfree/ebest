# frozen_string_literal: true

class CreateHistories < ActiveRecord::Migration[5.2]
  def change
    create_table :histories do |t|
      t.belongs_to :operator, polymorphic: true
      t.belongs_to :operatable, polymorphic: true
      t.integer :history_type, null: false
      t.jsonb :params

      t.timestamps
    end
  end
end
