# frozen_string_literal: true

class AddAeGstAmountInCentToOrderItems < ActiveRecord::Migration[5.2]
  def change
    add_column :order_items, :ae_gst_amount_in_cent, :integer, default: 0
  end
end
