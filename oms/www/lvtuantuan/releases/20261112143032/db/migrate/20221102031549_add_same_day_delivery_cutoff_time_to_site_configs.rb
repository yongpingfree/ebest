# frozen_string_literal: true

class AddSameDayDeliveryCutoffTimeToSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :same_day_delivery_cutoff_time, :json, default: {}
  end
end
