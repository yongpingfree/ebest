# frozen_string_literal: true

namespace :sidekiq do
  desc "更新月销量"
  task :update_actual_monthly_sales_count_job, [:options] => [:environment] do |_, args|
    MagicBean::Item.find_each do |item|
      item.calculate_actual_monthly_sales_count
      item.save
    end
  end

  desc "生成优惠券"
  task :generate_coupons_job, [:options] => [:environment] do |_, args|

    options = DataEncrypt.aes128_decrypt(args[:options])
    options = ActiveSupport::JSON.decode(options)&.symbolize_keys

    coupon_template = MagicBean::CouponTemplate.find_by(id: options[:id])
    coupon_template.generate_coupons(options[:qty]) if coupon_template
  end

  desc "保存浏览记录"
  task :save_history_job, [:options] => [:environment] do |_, args|

    options = DataEncrypt.aes128_decrypt(args[:options])
    options = ActiveSupport::JSON.decode(options)&.symbolize_keys

    action_type = options[:action_type]
    page_type = options[:page_type]
    params = options[:params]&.deep_symbolize_keys

    operator = MagicBean::User.find_by(id: params[:operator_id])

    MagicBean::History.create!(
      operator: operator,
      action_type: action_type,
      page_type: page_type,
      store_id: params[:store_id],
      channel: params[:channel],
      params: params[:params]
    ) if operator
  end

  desc "生成 Promo Code"
  task :generate_promo_codes_job, [:options] => [:environment] do |_, args|

    options = DataEncrypt.aes128_decrypt(args[:options])
    options = ActiveSupport::JSON.decode(options)&.symbolize_keys

    pct = MagicBean::PromoCodeTemplate.find_by(id: options[:id])
    pct.generate_promo_codes(options[:qty]) if pct
  end
end
