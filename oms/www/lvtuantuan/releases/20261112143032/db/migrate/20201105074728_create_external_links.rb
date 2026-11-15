# frozen_string_literal: true
class CreateExternalLinks < ActiveRecord::Migration[5.2]
  def change
    create_table :external_links do |t|
      t.string :name
      t.string :link

      t.timestamps
    end
  end
end
