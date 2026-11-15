# frozen_string_literal: true
require "open-uri"

class GiftCardMailer < ApplicationMailer
  include ::BeansAdmin::Helpers::ExportHelper

  @@export_logger = ::Logger.new("./log/export.log")

  def coupons_export(email, order_by, ransack_params)

    @@export_logger.info("Gift card coupons export: time is #{Time.current}, email is #{email}, order_by is #{order_by}, ransack_params is #{ransack_params}")

    stores_hash = {}
    MagicBean::Store.all.each do |store|
      stores_hash[store.id.to_s] = store.name
    end

    # 传过来的order_by有可能是string或array
    order_by = ::BeansAdmin::Helpers::OrderBySanitizer.sanitize(order_by.to_s).presence
    tem_path = []
    package = Axlsx::Package.new do |p|
      headers = %w[卡号 PIN 金额 有效期 状态 所属门店]

      p.workbook.add_worksheet do |sheet|
        header_format = sheet.styles.add_style(bg_color: "fafafa", alignment: { wrap_text: true })
        row_format = sheet.styles.add_style(alignment: { wrap_text: true })

        # 设置每列宽度
        sheet.column_widths 15, 15, 15, 15, 15, 20
        sheet.add_row(headers, style: header_format)
        MagicBean::GiftCardCoupon.ransack(ransack_params).result.order(order_by).each do |coupon|
          store_names = coupon.store_ids.blank? ? "全部" : coupon.store_ids.map { |store_id| stores_hash[store_id.to_s] }.join(", ")
          coupon_row = [coupon.code, coupon.pin_code, coupon.denominations_in_yuan, coupon.expired_at.strftime("%Y-%m-%d %H:%M:%S"), I18n.t("attributes.gift_card_template/statuses.#{coupon.status}"), store_names]
          sheet.add_row(coupon_row, style: row_format)
        end
      end
    end

    @subject = "导出礼品卡列表-#{Time.now.strftime("%Y%m%d%H%M%L")}"
    attachments["#{@subject}.xlsx"] = package.to_stream.read
    mail(
      to: email,
      subject: @subject,
      template_path: "export_mailer",
      template_name: "export"
    )

    # 删除临时文件
    tem_path.compact.each { |path| FileUtils.rm(path) }

    decrease_export_list_count
  end
end
