# frozen_string_literal: true

class CreateAddresses < ActiveRecord::Migration[5.2]
  def change
    create_table :addresses do |t|
      t.string :province_name
      t.string :city_name
      t.string :county_name
      t.string :detail_info
      t.string :tel_number
      t.string :receiver_name
      t.string :postal_code
      t.boolean :is_default
      t.references :user

      t.timestamps
    end
  end
end
