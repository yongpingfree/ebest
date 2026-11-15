# frozen_string_literal: true

class AddIsBoxRegulationToSkus < ActiveRecord::Migration[5.2]
  def change
    add_column :stock_keeping_units, :is_box_regulation, :boolean, default: false
    add_column :order_items, :is_box_regulation, :boolean, default: false
  end
end
