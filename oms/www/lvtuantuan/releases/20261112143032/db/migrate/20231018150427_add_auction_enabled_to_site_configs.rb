# frozen_string_literal: true

class AddAuctionEnabledToSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :auction_enabled, :boolean, default: true, comment: "控制APP我的拍卖入口显示"
  end
end
