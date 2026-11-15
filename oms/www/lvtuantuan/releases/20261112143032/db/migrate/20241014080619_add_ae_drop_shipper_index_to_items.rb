# frozen_string_literal: true

class AddAeDropShipperIndexToItems < ActiveRecord::Migration[5.2]
  def change
    add_index :items, :ae_drop_shipper
  end
end
