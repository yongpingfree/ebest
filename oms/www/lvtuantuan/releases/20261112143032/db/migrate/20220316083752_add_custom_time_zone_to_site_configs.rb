# frozen_string_literal: true

class AddCustomTimeZoneToSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :custom_time_zone, :string
  end
end
