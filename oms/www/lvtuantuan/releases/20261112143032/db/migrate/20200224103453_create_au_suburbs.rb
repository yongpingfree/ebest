# frozen_string_literal: true

class CreateAuSuburbs < ActiveRecord::Migration[5.1]
  def change
    create_table :au_suburbs do |t|
      t.string :name
      t.string :state_name
      t.string :state_short_name
      t.string :postal_code
      t.float :latitude
      t.float :longitude

      t.index ["postal_code"], name: "index_au_suburbs_on_postal_code"
      t.index ["name"], name: "index_au_suburbs_on_name"
    end
  end
end
