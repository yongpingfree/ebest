# frozen_string_literal: true

namespace :mailer do
  desc "订单导出"
  task :mailer_order_export, [:options] => [:environment] do |_, args|

    options = decrypt_params(args[:options])
    order_ids = Rails.cache.fetch(options[:redis_key])

    OrderMailer.export(
      options[:email],
      order_ids,
      options[:order_by],
      options[:sku_id]
    ).deliver

    Rails.cache.delete options[:redis_key]
  end

  desc "售后导出"
  task :mailer_after_sales_export, [:options] => [:environment] do |_, args|

    options = decrypt_params(args[:options])
    after_sales_ids = Rails.cache.fetch(options[:redis_key])

    AfterSaleMailer.export(
      options[:email],
      after_sales_ids,
      options[:order_by],
    ).deliver

    Rails.cache.delete options[:redis_key]
  end

  desc "商品导出"
  task :mailer_items_export, [:options] => [:environment] do |_, args|

    options = decrypt_params(args[:options])

    ItemMailer.export(
      options[:email], options[:order_by], options[:on_sale], options[:delivery_type], options[:ransack_params], options[:channels]
    ).deliver
  end

  desc "礼品卡导出"
  task :mailer_gift_card_export, [:options] => [:environment] do |_, args|

    options = decrypt_params(args[:options])

    GiftCardMailer.coupons_export(
      options[:email], options[:order_by], options[:ransack_params]
    ).deliver
  end

  desc "商品销量导出"
  task :mailer_sales_export, [:options] => [:environment] do |_, args|
    StockKeepingUnitMailer.export(args[:options]).deliver
  end

  desc "商品计划销量导出"
  task :mailer_sales_plan_export, [:options] => [:environment] do |_, args|
    StockKeepingUnitMailer.sales_plan_export(args[:options]).deliver
  end

  desc "商品退货统计导出"
  task :mailer_sku_return_export, [:options] => [:environment] do |_, args|
    StockKeepingUnitMailer.sku_return_export(args[:options]).deliver
  end

  desc "到货通知统计导出"
  task :mailer_sku_in_stock_notice_export, [:options] => [:environment] do |_, args|
    StockKeepingUnitMailer.sku_in_stock_notice_export(args[:options]).deliver
  end

  desc "供应商商品导出"
  task :mailer_sku_suppliers_export, [:options] => [:environment] do |_, args|
    StockKeepingUnitMailer.suppliers_export(args[:options]).deliver
  end

  desc "操作记录导出"
  task :mailer_operation_record_export, [:options] => [:environment] do |_, args|
    OperationRecordMailer.export(args[:options]).deliver
  end

  desc "每日会员订单数据导出"
  task mailer_member_order_data_export: :environment do |t, args|
    # 任务会在凌晨执行，要哪前一天的日期
    OrderMailer.member_order_data_export_by_date(Date.yesterday, "yanan.z@ebest.com.au").deliver
  end

  desc "Promo Codes导出"
  task :mailer_promo_codes_export, [:options] => [:environment] do |_, args|

    options = decrypt_params(args[:options])

    PromoCodeMailer.export(
      options[:email], options[:order_by], options[:ransack_params]
    ).deliver
  end

  private
  def decrypt_params(options)
    options = DataEncrypt.aes128_decrypt(options)
    ActiveSupport::JSON.decode(options)&.symbolize_keys
  end
end
