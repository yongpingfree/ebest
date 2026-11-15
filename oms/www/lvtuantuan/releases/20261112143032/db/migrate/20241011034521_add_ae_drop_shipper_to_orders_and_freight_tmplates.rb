# frozen_string_literal: true

class AddAeDropShipperToOrdersAndFreightTmplates < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :ae_drop_shipper, :boolean, default: false
    add_column :freight_templates, :ae_drop_shipper, :boolean, default: false
  end
end
