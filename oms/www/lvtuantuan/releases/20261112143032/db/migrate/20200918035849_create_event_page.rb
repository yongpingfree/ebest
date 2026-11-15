# frozen_string_literal: true

class CreateEventPage < ActiveRecord::Migration[5.2]
  def change
    create_table :event_pages do |t|
      t.string :slug
      t.string :name
      t.integer :event_form_records_count

      t.timestamps
    end

    add_reference :event_form_records, :event_page, index: true
  end
end
