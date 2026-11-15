# frozen_string_literal: true

class AddCutoffTimeToSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :cutoff_time, :string, array: true, default: []
  end
end
