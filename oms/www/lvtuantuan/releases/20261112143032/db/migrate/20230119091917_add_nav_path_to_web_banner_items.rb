# frozen_string_literal: true

class AddNavPathToWebBannerItems < ActiveRecord::Migration[5.2]
  def change
    add_column :web_banner_items, :nav_path_type, :string
    add_column :web_banner_items, :nav_path_id, :bigint
    add_column :web_banner_items, :nav_path, :json
  end
end
