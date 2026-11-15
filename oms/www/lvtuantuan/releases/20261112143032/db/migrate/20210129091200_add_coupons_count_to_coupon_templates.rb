# frozen_string_literal: true

class AddCouponsCountToCouponTemplates < ActiveRecord::Migration[5.2]
  def change
    add_column :coupon_templates, :coupons_count, :integer, default: 0

    say_with_time "update templates coupons_count" do
      MagicBean::CouponTemplate.reset_column_information

      MagicBean::CouponTemplate.find_each do |template|
        template.coupons_count = template.coupons.count
        template.save(validate: false)
      end
    end
  end
end
