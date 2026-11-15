# frozen_string_literal: true

class AddNewbieCouponTemplateIdToSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :newbie_coupon_template_id, :integer
  end
end
