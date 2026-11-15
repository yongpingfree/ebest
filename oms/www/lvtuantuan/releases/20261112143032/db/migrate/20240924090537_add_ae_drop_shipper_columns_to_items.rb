# frozen_string_literal: true

class AddAeDropShipperColumnsToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :ae_drop_shipper, :boolean, default: false
    add_column :items, :ae_drop_shipper_product_id, :string
  end
end
