# frozen_string_literal: true

class AddGstColumnsToOrderItems < ActiveRecord::Migration[5.2]
  def change
    add_column :order_items, :gst_percent, :integer, default: 0
    add_column :order_items, :gst_amount_in_cent, :decimal, precision: 12, scale: 2, default: 0.0
  end
end
