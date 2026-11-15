# frozen_string_literal: true

class AddGstColumnsToSuppliers < ActiveRecord::Migration[5.2]
  def change
    add_column :suppliers, :include_gst, :boolean, default: false
    add_column :suppliers, :gst_amount, :decimal, precision: 12, scale: 2
  end
end
