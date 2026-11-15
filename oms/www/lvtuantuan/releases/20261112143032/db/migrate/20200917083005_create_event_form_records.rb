# frozen_string_literal: true

class CreateEventFormRecords < ActiveRecord::Migration[5.2]
  def change
    create_table :event_form_records do |t|
      t.references :user, foreign_key: true
      t.string :event_slug
      t.json :data, default: {}

      t.timestamps
    end
    add_index :event_form_records, :event_slug
  end
end
