# frozen_string_literal: true

class RenameAeGstAmoutInCent < ActiveRecord::Migration[5.2]
  def change
    rename_column :orders, :ae_gst_amout_in_cent, :ae_gst_amount_in_cent
  end
end
