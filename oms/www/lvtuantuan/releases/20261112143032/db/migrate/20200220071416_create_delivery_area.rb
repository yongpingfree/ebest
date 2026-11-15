# frozen_string_literal: true

class CreateDeliveryArea < ActiveRecord::Migration[5.2]
  def change
    create_table :delivery_areas do |t|
      t.string :suburb
      t.string :postal_code
      t.float :latitude
      t.float :longitude
      t.string :google_place_id

      t.timestamps null: false
    end
  end
end
