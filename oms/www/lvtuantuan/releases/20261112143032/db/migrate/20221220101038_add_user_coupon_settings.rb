# frozen_string_literal: true

class AddUserCouponSettings < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :info_finished_coupon_template_id, :integer
    add_column :site_configs, :birthday_coupon_template_id, :integer
  end
end
