# frozen_string_literal: true

class AddShipmentNoToLogistics < ActiveRecord::Migration[5.2]
  def change
    add_column :logistics, :shipment_no, :string, comment: "erp发货单号"
  end
end
