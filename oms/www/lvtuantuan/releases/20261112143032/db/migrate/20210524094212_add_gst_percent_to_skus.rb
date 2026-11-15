# frozen_string_literal: true

class AddGstPercentToSkus < ActiveRecord::Migration[5.2]
  def change
    add_column :stock_keeping_units, :gst_percent, :integer, default: 0
  end
end
