# frozen_string_literal: true

class AfterSaleMailer < ApplicationMailer
  include ::BeansAdmin::Helpers::ExportHelper

  @@export_logger = ::Logger.new("./log/export.log")

  def export(email, after_sales_ids, order_by)
    @@export_logger.info("AfterSales export: time is #{Time.current}, email is #{email}, order_by is #{order_by}")

    order_by = order_by.is_a?(Array) ? order_by.compact.map(&:strip).join(", ") : order_by.to_s
    order_by = ::BeansAdmin::Helpers::OrderBySanitizer.sanitize(order_by)
    order_by = "created_at desc" if order_by.blank?

    package = Axlsx::Package.new do |p|
      headers = %w[agreed_at order_no refund_no applicant_type p_category c_category sku title internal_reason department is_real_claim audit_explain return_amount return_integral_amount return_gift_card_amount return_coupon_amount]
      types = %i[string string string string string string string string string string string string float float float float]

      p.workbook.add_worksheet do |sheet|
        sheet.add_row headers

        MagicBean::AfterSale.where(id: after_sales_ids).includes(:order, order_items: [:stock_keeping_unit, item: [:translations, category: :translations, parent_category: :translations]]).order(order_by).each_slice(200) do |slice_after_sales|
          slice_after_sales.each do |as|
            as.after_sales_order_items.each do |after_sales_order_item|
              order_item = after_sales_order_item.order_item
              sku = order_item.stock_keeping_unit
              item = order_item.item
              is_real_claim_text = as.is_real_claim ? "是" : "否"
              
              row = [as.agreed_at, as.order_no, as.refund_no,
                as.applicant_type.present? ? I18n.t("activerecord.attributes.magic_bean/after_sale.applicant_types.#{as.applicant_type}") : "",
                item.parent_category.name, item.category.name, sku.no, order_item.sku_human_title,
                as.internal_reason.present? ? I18n.t("activerecord.attributes.magic_bean/after_sale.internal_reasons.#{as.internal_reason}") : "",
                as.department.present? ? I18n.t("activerecord.attributes.magic_bean/after_sale.departments.#{as.department}") : "",
                is_real_claim_text, as.audit_explain, after_sales_order_item.real_amount_in_yuan, after_sales_order_item.cost_integral, after_sales_order_item.gift_card_amount_in_yuan, as.return_coupon_amount_in_yuan]
              
              sheet.add_row(row, types: types)
            end            
          end
        end
      end
    end

    @subject = "导出售后-#{Time.current.strftime("%Y-%m-%d-%H-%M")}"
    attachments["#{@subject}.xlsx"] = package.to_stream.read
    mail(
      to: email,
      subject: @subject,
      template_path: "export_mailer",
      template_name: "export"
    )

    decrease_export_list_count
  end
end
