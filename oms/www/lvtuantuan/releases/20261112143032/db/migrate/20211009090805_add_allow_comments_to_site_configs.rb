# frozen_string_literal: true

class AddAllowCommentsToSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :allow_comments, :boolean, default: true
  end
end
