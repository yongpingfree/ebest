# frozen_string_literal: true

class AddDirectRefundReasonsToSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :direct_refund_reasons, :string, array: true, default: []
    add_column :site_configs, :after_sale_reasons, :string, array: true, default: []
  end
end
