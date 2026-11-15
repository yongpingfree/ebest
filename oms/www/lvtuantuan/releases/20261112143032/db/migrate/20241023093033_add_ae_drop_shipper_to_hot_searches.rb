# frozen_string_literal: true

class AddAeDropShipperToHotSearches < ActiveRecord::Migration[5.2]
  def change
    add_column :hot_searches, :ae_drop_shipper, :boolean, default: false
  end
end
