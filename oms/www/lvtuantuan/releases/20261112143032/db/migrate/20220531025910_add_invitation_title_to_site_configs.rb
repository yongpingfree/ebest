# frozen_string_literal: true

class AddInvitationTitleToSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :invitation_title, :string
  end
end
