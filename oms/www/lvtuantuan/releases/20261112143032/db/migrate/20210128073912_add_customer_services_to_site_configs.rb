# frozen_string_literal: true

class AddCustomerServicesToSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :customer_services, :string, array: true, default: []
  end
end
