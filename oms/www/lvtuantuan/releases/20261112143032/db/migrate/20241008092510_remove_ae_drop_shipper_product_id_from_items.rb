# frozen_string_literal: true

class RemoveAeDropShipperProductIdFromItems < ActiveRecord::Migration[5.2]
  def change
    remove_column :items, :ae_drop_shipper_product_id, :string
  end
end
