# frozen_string_literal: true

class AddUserDefaultAvatarToSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :user_default_avatar, :string
  end
end
