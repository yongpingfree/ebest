# frozen_string_literal: true

class AddInvitationConfigToSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :invitation, :json, default: {}
    remove_column :site_configs, :invitation_title, :string
  end
end
