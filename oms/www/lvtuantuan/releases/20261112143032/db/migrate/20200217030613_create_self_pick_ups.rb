# frozen_string_literal: true

class CreateSelfPickUps < ActiveRecord::Migration[5.2]
  def change
    create_table :self_pick_ups do |t|
      t.string :name
      t.string :email
      t.string :address
      t.string :mobile
      t.string :google_place_id
      t.string :province_name
      t.string :city_name
      t.string :street
      t.string :street_number
      t.string :opening_hours, comment: "营业时间"
      t.string :postal_code
      t.float :latitude
      t.float :longitude

      t.timestamps null: false
    end

    add_reference :orders, :self_pick_up, foreign_key: true
  end
end
