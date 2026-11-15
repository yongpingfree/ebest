# frozen_string_literal: true

class AddWatermarkAttributesToSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :watermark_attributes, :json, default: {}
  end
end
