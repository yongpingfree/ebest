# frozen_string_literal: true

class AddAuSuburbIdToDeliveryAreas < ActiveRecord::Migration[5.2]
  def change
    add_column :delivery_areas, :au_suburb_id, :integer
    add_index :delivery_areas, :au_suburb_id
    remove_column :delivery_areas, :google_place_id, :string
  end
end
