# frozen_string_literal: true

class AddKuaimaDeliveryMaxCountToSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :kuaima_delivery_max_count, :integer, default: 0, comment: "每天快马配送最大数量"
  end
end
