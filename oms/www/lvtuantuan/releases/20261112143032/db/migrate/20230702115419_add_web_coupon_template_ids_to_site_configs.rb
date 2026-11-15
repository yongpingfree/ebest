class AddWebCouponTemplateIdsToSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :web_invited_coupon_template_ids, :integer, array: true, default: []
    add_column :site_configs, :web_finish_order_coupon_template_ids_to_inviter, :integer, array: true, default: []
    add_column :site_configs, :web_info_finished_coupon_template_id, :integer
    add_column :site_configs, :web_birthday_coupon_template_id, :integer
  end
end
