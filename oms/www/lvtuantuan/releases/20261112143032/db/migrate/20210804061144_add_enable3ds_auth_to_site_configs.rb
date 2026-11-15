# frozen_string_literal: true

class AddEnable3dsAuthToSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :enable_commweb_3ds_auth, :boolean, default: false
  end
end
