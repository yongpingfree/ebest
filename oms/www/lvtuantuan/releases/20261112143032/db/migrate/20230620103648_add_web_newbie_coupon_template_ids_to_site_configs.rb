class AddWebNewbieCouponTemplateIdsToSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :web_newbie_coupon_template_ids, :integer, array: true, default: []
  end
end
