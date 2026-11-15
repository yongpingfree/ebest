# frozen_string_literal: true

class AddAeOrderGstPercentToSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :ae_order_gst_percent, :integer, default: 10
  end
end
