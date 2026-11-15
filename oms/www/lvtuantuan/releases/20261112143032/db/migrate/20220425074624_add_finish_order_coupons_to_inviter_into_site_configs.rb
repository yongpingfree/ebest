# frozen_string_literal: true

class AddFinishOrderCouponsToInviterIntoSiteConfigs < ActiveRecord::Migration[5.2]
  def change
      add_column :site_configs, :finish_order_coupon_template_ids_to_inviter, :integer, default: [], array: true
  end
end
