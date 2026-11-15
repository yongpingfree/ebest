# frozen_string_literal: true

class AddBottomSettingsToSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :bottom_settings, :jsonb, default: {}
  end
end
