# frozen_string_literal: true

class AddKindToSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :kind, :integer, default: 1
  end
end
