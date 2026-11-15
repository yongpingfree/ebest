# frozen_string_literal: true

class ChangeReturnReceiverPropertiesForSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    remove_column :site_configs, :return_receiver_properties, :string
    add_column :site_configs, :return_receiver_properties, :json, dfault: {}
  end
end
