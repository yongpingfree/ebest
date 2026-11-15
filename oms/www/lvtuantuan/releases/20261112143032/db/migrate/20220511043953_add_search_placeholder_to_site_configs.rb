class AddSearchPlaceholderToSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :search_placeholder, :string
  end
end
