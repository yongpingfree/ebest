# frozen_string_literal: true
require "open-uri"

class PromoCodeMailer < ApplicationMailer
  include ::BeansAdmin::Helpers::ExportHelper

  @@export_logger = ::Logger.new("./log/export.log")

  def export(email, order_by, ransack_params)
    @@export_logger.info("Promo codes export: time is #{Time.current}, email is #{email}, order_by is #{order_by}, ransack_params is #{ransack_params}")

    # 传过来的order_by有可能是string或array
    order_by = ::BeansAdmin::Helpers::OrderBySanitizer.sanitize(order_by.to_s).presence || "created_at DESC"

    csv_string = CSV.generate(encoding: "UTF-8") do |csv|
      csv << ["编号", "标题", "是否启用", "开始日期", "结束日期", "管理员备注", "Promo code编号", "Code", "订单"]
      MagicBean::PromoCodeTemplate.includes(promo_codes: :orders).ransack(ransack_params).result.order(order_by).each do |template|
        template_row = [template.id, template.title, template.enabled ? "是" : "否", template.start_on, template.end_on, template.remark]
        template.promo_codes.each do |promo_code|
          order_no = promo_code.orders.present? ? "no: #{promo_code.orders.pluck(:no).join(', ')}" : nil
          row = template_row + [promo_code.id, "code: #{promo_code.code}", order_no]
          csv << row
        end

        csv << template_row if template.promo_codes.blank?
      end
    end

    csv_string_with_utf8_bom = "\uFEFF" + csv_string

    @subject = "导出PromoCode列表-#{Time.current.strftime("%Y-%m-%d-%H-%M")}"
    attachments["#{@subject}.csv"] = csv_string_with_utf8_bom
    mail(
      to: email,
      subject: @subject,
      template_path: "export_mailer",
      template_name: "export"
    )

    decrease_export_list_count
  end
end
