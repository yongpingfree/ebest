# frozen_string_literal: true

class AddAreaRefferenceToAddresses < ActiveRecord::Migration[5.2]
  def change
    add_belongs_to :addresses, :province, foreign_key: true
    add_belongs_to :addresses, :city, foreign_key: true
    add_belongs_to :addresses, :county, foreign_key: true
    remove_column :addresses, :province_name, :string
    remove_column :addresses, :city_name, :string
    remove_column :addresses, :county_name, :string
  end
end
