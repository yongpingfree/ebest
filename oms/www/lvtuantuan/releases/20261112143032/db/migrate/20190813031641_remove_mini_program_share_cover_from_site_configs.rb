# frozen_string_literal: true

class RemoveMiniProgramShareCoverFromSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    remove_column :site_configs, :mini_program_share_cover
    remove_column :site_configs, :mini_program_share_title
  end
end
