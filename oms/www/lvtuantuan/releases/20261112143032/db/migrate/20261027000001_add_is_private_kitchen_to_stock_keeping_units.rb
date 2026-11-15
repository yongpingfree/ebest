# frozen_string_literal: true

class AddIsPrivateKitchenToStockKeepingUnits < ActiveRecord::Migration[5.2]
  def change
    add_column :stock_keeping_units, :is_private_kitchen, :boolean, default: false, comment: "是否私厨"
  end
end
