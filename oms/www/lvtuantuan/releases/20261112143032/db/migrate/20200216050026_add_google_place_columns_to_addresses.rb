# frozen_string_literal: true

class AddGooglePlaceColumnsToAddresses < ActiveRecord::Migration[5.2]
  def change
    remove_belongs_to :addresses, :province, foreign_key: true
    remove_belongs_to :addresses, :city, foreign_key: true
    remove_belongs_to :addresses, :county, foreign_key: true

    add_column :addresses, :google_place_id, :string
    add_column :addresses, :province_name, :string
    add_column :addresses, :city_name, :string
  end
end
