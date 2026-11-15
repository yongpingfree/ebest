# frozen_string_literal: true

class AddEtaAndAtaToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :eta, :datetime, comment: "WMS预计配送时间"
    add_column :orders, :ata, :datetime, comment: "WMS实际配送时间"
  end
end
