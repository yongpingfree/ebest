# frozen_string_literal: true

class AddAeDropShipperToCustomLists < ActiveRecord::Migration[5.2]
  def change
    add_column :custom_lists, :ae_drop_shipper, :boolean, default: false
  end
end
