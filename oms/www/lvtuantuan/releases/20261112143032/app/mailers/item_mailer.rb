# frozen_string_literal: true
require "open-uri"

class ItemMailer < ApplicationMailer
  include ::BeansAdmin::Helpers::ExportHelper
  include ::BeansAdmin::Helpers::ItemsHelper
  include ::BeansAdmin::Helpers::FileUploadHelper

  @@export_logger = ::Logger.new("./log/export.log")

  def export(email, order_by, on_sale, delivery_type, ransack_params, channels = [])
    @@export_logger.info("Items export: time is #{Time.current}, email is #{email}, order_by is #{order_by}, on_sale is #{on_sale}, delivery_type is #{delivery_type}, ransack_params is #{ransack_params}")

    # 传过来的order_by有可能是string或array
    order_by = order_by.split(",").presence if order_by.present? && order_by.is_a?(String)
    default_order = ["position ASC", "created_at DESC"]

    # 待同步sku数量
    not_synced_skus =
      MagicBean::OrderItem.where(
        order_id: MagicBean::Order.paid.where(sync_status: [:pending, :confirmed]).where("delivery_date >= ?", Date.current.to_s).select(:id)
      ).group(:stock_keeping_unit_id).sum(:quantity)

    gift_not_synced_quantity_hash = {}

    MagicBean::Order.where.not(gifts_properties: nil).or(MagicBean::Order.where.not(pool_gifts_properties: nil)).paid.where(sync_status: [:pending, :confirmed]).where("delivery_date >= ?", Date.current.to_s).ransack({ store_id_eq: ransack_params["store_id_eq"] }).result.each do |order|
      ((order.gifts_properties || []) + (order.pool_gifts_properties || [])).each do |gift|
        gift_not_synced_quantity_hash["#{gift["stock_keeping_unit_id"]}"] ||= 0
        gift_not_synced_quantity_hash["#{gift["stock_keeping_unit_id"]}"] += gift["quantity"]
      end
    end

    # 先查出所有限时优惠的sku的价格
    promotion_skus_hash = {}
    MagicBean::TimeLimitedPromotion.includes(:time_limited_promotion_prices).active.each do |promotion|
      promotion.time_limited_promotion_prices.each do |promotion_price|
        promotion_skus_hash[promotion_price.stock_keeping_unit_id] = promotion_price.price_in_yuan
      end
    end

    @subject = "导出商品列表-#{Time.current.strftime("%Y-%m-%d-%H-%M")}"
    # 文件名加上随机数
    file_name = "#{@subject}-#{SecureRandom.hex(4)}.csv"
    file_path = Rails.root.join("tmp", file_name)

    # 先写入 BOM，避免csv文件打开乱码
    File.open(file_path, "w") { |f| f.write("\uFEFF") }

    CSV.open(file_path, "a", write_headers: true, headers: %w(导入编号 负责人 商品名称 商品英文名 短标题 平台限制 主产品分类 主产品一级分类 次产品分类 次产品一级分类 网站分类 网站一级分类 品牌 发货方式 状态 AE端是否不可销售 product_id 货号 SKU规格 SKU的售价 SKU限时优惠价格 SKU划线价 可销售库存 是否特品 是否私厨 GMV等级 GP等级 名义毛利率(%) 周转率(%) 订单待同步WMS数量汇总 赠品待同步WMS数量汇总 barcode GST% 营销模式 入驻商 供应商 供应商价格($) 首次上架开卖时间)) do |csv|
      @collection = MagicBean::Item
      @collection = @collection.delivery_type_contains(delivery_type) if delivery_type
      @collection = @collection.channels_contains(channels) if channels.present?
      @collection = @collection.on_sale if on_sale
      items = @collection.includes(:translations, [category: :translations], [parent_category: :translations], [minor_category: :parent], :default_freight_templates, [stock_keeping_units: :newest_supplier], :qa_and_guarantee, [brand: :translations], :taggings, :web_item).ransack(ransack_params)
      order_by = (order_by.compact.map(&:strip) + default_order).uniq if order_by.present?
      items.sorts = order_by || default_order
      items.result.group(:id).each_slice(200) do |slice_items|
        slice_items.each do |item|
          item_row = ["item_no: #{item.no}", item.leader, item.title_zh_cn, item.title_en, item.short_title, item.channels.join("|"), item.category&.name, item.parent_category&.name, item.minor_category&.name, item.minor_category&.parent&.name, item.web_category_name, item.parent_web_category_name, item.brand&.name, item.delivery_type.map { |type| I18n.t("activerecord.attributes.magic_bean/order.delivery_types.#{type}") }.join(", "), I18n.t("attributes.item/listing_types.#{item.listing_type}"), item.ae_unsaleable ? "是" : "否"]
          item.stock_keeping_units.each do |sku|
            supplier = sku.newest_supplier
            supplier_name = item.ae_drop_shipper ? "跨境购" : supplier&.name
            supplier_cost = item.ae_drop_shipper ? sku.ae_price_in_yuan : supplier&.cost_in_yuan
            sku_row = item_row + [sku.id, "no: #{sku.no}", sku.properties_text, sku.price_in_yuan, promotion_skus_hash[sku.id], sku.strikethrough_price_in_yuan, sku.quantity, sku.is_special ? "是" : "否", sku.is_private_kitchen ? "是" : "否", sku.gmv_sku_level, sku.gp_sku_level, sku.nominal_gross_margin_ratio, sku.turnover_rate, not_synced_skus[sku.id].to_i, gift_not_synced_quantity_hash["#{sku.id}"].to_i, "upc: #{sku.barcode}", sku.gst_percent, I18n.t("activerecord.attributes.magic_bean/stock_keeping_unit/marketing_modes.#{sku.marketing_mode}"), sku.shoppingunit, supplier_name, supplier_cost, sku.first_sale_at]
            csv << sku_row
          end
        end
      end
    end

    @file_url = aws_upload!(file_path, file_name)
    File.delete(file_path) if File.exist?(file_path)
    # 2 天后删除 aws 文件
    DeleteAwsFileJob.set(wait: 2.days).perform_later(@file_url)

    mail(
      to: email,
      subject: @subject,
      template_path: "export_mailer",
      template_name: "export"
    )

    decrease_export_list_count
  end

  def import(email, file_url)
    error_messages = []
    count = 0
    admin_user = MagicBean::AdminUser.find_by(email: email)

    xlsx = Roo::Spreadsheet.open file_url
    result = xlsx.sheet(0).parse(headers: true)

    MagicBean::Item.transaction do
      result[2..-1].each.with_index(3) do |row, i|
        item_attributes, item, err_message, log_messages = set_import_params(row, admin_user)
        if err_message.present?
          error_messages << "第#{i}行: #{err_message.join("，")}"
          next
        end

        log_message = log_messages.join(", ")

        if item.present?
          if item.update(item_attributes)
            admin_user.operation_records.create(operatable: item, content: log_message, store_id: item.store_id) if log_message.present?
            count += 1
          else
            error_messages << "第#{i}行: #{item.errors.full_messages.join("，")}"
          end
        else
          resource = MagicBean::Item.new(item_attributes)
          if resource.save
            admin_user.operation_records.create(operatable: resource, content: log_message, store_id: resource.store_id) if log_message.present?
            count += 1
          else
            error_messages << "第#{i}行: #{resource.errors.full_messages.join("，")}"
          end
        end
      end
    end

    @messages = error_messages.presence || ["本次成功导入#{count}条数据"]
    @subject = "异步导入产品结果-#{Time.current.strftime("%Y-%m-%d-%H-%M")}"

    if email.present?
      mail(
        to: email,
        subject: @subject,
        template_path: "import_mailer",
        template_name: "import"
      )
    end

    # 删除在线文件
    Aws::CustomOss.delete_file(file_url)
  end

  def notify_basic_import(email, error_messages = [])
    @messages = error_messages.presence || ["本次成功导入所有数据"]
    @subject = "异步导入产品结果-#{Time.current.strftime("%Y-%m-%d-%H-%M")}"

    if email.present?
      mail(
        to: email,
        subject: @subject,
        template_path: "import_mailer",
        template_name: "import"
      )
    end
  end
end
