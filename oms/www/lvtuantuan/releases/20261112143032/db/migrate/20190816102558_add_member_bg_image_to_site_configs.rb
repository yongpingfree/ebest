# frozen_string_literal: true

class AddMemberBgImageToSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :member_bg_image, :string
  end
end
