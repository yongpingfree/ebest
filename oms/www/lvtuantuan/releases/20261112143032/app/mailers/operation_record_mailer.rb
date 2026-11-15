# frozen_string_literal: true

class OperationRecordMailer < ApplicationMailer
  include ::BeansAdmin::Helpers::ExportHelper

  @@export_logger = ::Logger.new("./log/export.log")
  def before_export(options)
    options = DataEncrypt.aes128_decrypt(options)
    options = ActiveSupport::JSON.decode(options)&.symbolize_keys

    @@export_logger.info("Operation record export: time is #{Time.current}, options is #{options}")

    admin_user = MagicBean::AdminUser.find(options[:user_id])
    user_ability = MagicBean::Ability.new(admin_user)

    [options, user_ability]
  end

  def export(options)
    options, user_ability = before_export(options)
    opt_params = options[:params]

    csv_string = CSV.generate(encoding: "UTF-8") do |csv|
      csv << %w[操作者 操作对象 内容 操作平台 创建时间]

      collection = MagicBean::OperationRecord.accessible_by(user_ability).ransack(opt_params.merge(store_id_eq: options[:store_id])).result

      if opt_params["order_no_or_after_sale_refund_no"].present?
        collection = collection.where(operatable_type: "MagicBean::Order", operatable_id: MagicBean::Order.ransack({ no_cont: opt_params["order_no_or_after_sale_refund_no"] }).result.select(:id))
                        .or(collection.where(operatable_type: "MagicBean::AfterSale", operatable_id: MagicBean::AfterSale.ransack({ refund_no_cont: opt_params["order_no_or_after_sale_refund_no"] }).result.select(:id)))
      elsif opt_params["item_title"].present?
        collection = collection.where(operatable_type: "MagicBean::Item", operatable_id: MagicBean::Item.ransack({ translated_searchable_title_cont: opt_params["item_title"] }).result.select(:id))
      end

      collection.find_each do |obj|
        csv << [obj.admin_user&.name, obj.operatable_title, obj.content, obj.human_channel, I18n.l(obj.created_at, format: :long)]
      end
    end

    csv_string_with_utf8_bom = "\uFEFF" + csv_string

    @subject = "操作记录列表-#{Time.now.strftime("%Y%m%d%H%M%L")}"
    attachments["#{@subject}.csv"] = csv_string_with_utf8_bom
    mail(
      to: options[:email],
      subject: @subject,
      template_path: "export_mailer",
      template_name: "export"
    )

    decrease_export_list_count

  end
end
