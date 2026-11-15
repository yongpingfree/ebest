# frozen_string_literal: true

class AddInvitedCouponTemplateIdsToSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :invited_coupon_template_ids, :integer, array: true, default: []
  end
end
