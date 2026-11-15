# frozen_string_literal: true

class AddOrderBoxRegulationSettingsToSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :order_box_regulation_settings, :jsonb, default: {}
  end
end
