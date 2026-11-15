# frozen_string_literal: true

class AddAppVersionToSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :app_version, :json, defalut: {}
  end
end
