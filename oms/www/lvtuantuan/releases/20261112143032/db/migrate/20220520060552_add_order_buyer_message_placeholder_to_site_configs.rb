# frozen_string_literal: true

class AddOrderBuyerMessagePlaceholderToSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :order_buyer_message_placeholder, :string
  end
end
