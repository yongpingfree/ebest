# frozen_string_literal: true

class AddMiniProgramShareCoverToSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :mini_program_share_cover, :string
    add_column :site_configs, :mini_program_share_title, :string
  end
end
