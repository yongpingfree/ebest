# frozen_string_literal: true

class ChangeNewbieCouponTemplateIdFromSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    remove_column :site_configs, :newbie_coupon_template_id
    add_column :site_configs, :newbie_coupon_template_ids, :integer, array: true, default: []
  end
end
