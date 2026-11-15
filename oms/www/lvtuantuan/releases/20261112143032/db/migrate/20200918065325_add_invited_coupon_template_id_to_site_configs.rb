# frozen_string_literal: true

class AddInvitedCouponTemplateIdToSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :invited_coupon_template_id, :integer
  end
end
