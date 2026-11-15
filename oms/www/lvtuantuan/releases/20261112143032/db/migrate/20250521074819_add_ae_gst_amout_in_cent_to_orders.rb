# frozen_string_literal: true

class AddAeGstAmoutInCentToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :ae_gst_amout_in_cent, :integer, default: 0
  end
end
