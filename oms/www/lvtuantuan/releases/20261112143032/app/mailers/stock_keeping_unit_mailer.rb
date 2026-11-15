# frozen_string_literal: true
require "open-uri"

class StockKeepingUnitMailer < ApplicationMailer
  include ::BeansAdmin::Helpers::SkuSalesHelper
  include ::BeansAdmin::Helpers::ExportHelper

  @@export_logger = ::Logger.new("./log/export.log")
  def before_export(options)
    options = DataEncrypt.aes128_decrypt(options)
    options = ActiveSupport::JSON.decode(options)&.symbolize_keys

    @@export_logger.info("Sku sales export: time is #{Time.current}, options is #{options}")

    admin_user = MagicBean::AdminUser.find(options[:user_id])
    user_ability = MagicBean::Ability.new(admin_user)

    [options, user_ability]
  end

  def export(options)
    options, _ = before_export(options)

    admin_user = MagicBean::AdminUser.find options[:user_id]
    sales_collections(options[:params], options[:order_by], options[:store_id], admin_user)
    sku_return_hash = sales_collections_returns_data([], options[:params], admin_user)
    shopline_sale_and_refund_hash = shopline_sku_sales_collections(options[:params], options[:store_id], admin_user)

    csv_string = CSV.generate(encoding: "UTF-8") do |csv|
      csv << %w[product_id 导出编号 产品中文标题 产品英文标题 产品短标题 规格 是否特品 营销模式 一级分类 分类 UPC SKU 自营订单销量 自营订单总销售额(券前) 自营订单总销售额 自营订单退货商品数量 自营订单退货商品金额 Shopline订单销量 Shopline订单总销售额 Shopline订单退货商品数量 Shopline订单退货商品金额]

      @collection.find_each do |sku|
        special_text = sku.is_special ? "是" : "否"
        marketing_mode_text = I18n.t("activerecord.attributes.magic_bean/stock_keeping_unit/marketing_modes.#{sku.marketing_mode}")
        return_hash = sku_return_hash["#{sku.id}"]
        shopline_sale_and_refund_data = shopline_sale_and_refund_hash["#{sku.no}-#{sku.store_id}"]
        sum_after_sale_quantity = return_hash.present? ? return_hash[:sum_after_sale_quantity] : 0
        sum_after_sale_in_yuan = return_hash.present? ? return_hash[:sum_after_sale_in_yuan] : 0
        shopline_sales_count = shopline_sale_and_refund_data.present? ? shopline_sale_and_refund_data[:sales_count] : 0
        shopline_sales_amount = shopline_sale_and_refund_data.present? ? shopline_sale_and_refund_data[:sales_amount] : 0
        shopline_redund_count = shopline_sale_and_refund_data.present? ? shopline_sale_and_refund_data[:redund_count] : 0
        shopline_redund_amount = shopline_sale_and_refund_data.present? ? shopline_sale_and_refund_data[:redund_amount] : 0

        sku_row = [sku.id, "item_no: #{sku.item.no}", sku.title_zh_cn, sku.title_en, sku.short_title, sku.properties_text, special_text, marketing_mode_text, sku.parent_category_name, sku.category_name, "UPC: #{sku.barcode}", "SKU: #{sku.no}", sku.sales_count, sku.sum_original_amount_in_yuan, sku.sum_price_in_yuan, sum_after_sale_quantity, sum_after_sale_in_yuan, shopline_sales_count, shopline_sales_amount, shopline_redund_count, shopline_redund_amount]
        csv << sku_row
      end
    end

    csv_string_with_utf8_bom = "\uFEFF" + csv_string

    @subject = "导出商品销量列表-#{Time.now.strftime("%Y%m%d%H%M%L")}"
    attachments["#{@subject}.csv"] = csv_string_with_utf8_bom
    mail(
      to: options[:email],
      subject: @subject,
      template_path: "export_mailer",
      template_name: "export"
    )

    decrease_export_list_count
  end

  def sales_plan_export(options)
    options, _ = before_export(options)
    sales_plan_collections(options[:params], options[:order_by], options[:store_id])
    sku_valid_inventory_dates_hash = sales_plan_sku_valid_inventory_dates_hash(options[:params], options[:store_id])
    reserved_quantity_hash = sku_reserved_quantity_hash(options[:store_id])

    order_created_at_start_time, order_created_at_end_time = time_range_processor(
      options.dig(:params, "order_created_at_gteq"),
      options.dig(:params, "order_created_at_lteq")
    )

    # 获取wms未同步sku数量
    not_synced_skus_quantity = MagicBean::OrderItem.where(
      order_id: MagicBean::Order.paid.where(sync_status: [:pending, :confirmed]).where("delivery_date >= ?", Date.current.to_s).select(:id),
    ).group(:stock_keeping_unit_id).sum(:quantity)

    # 统计赠品数
    gift_quantity_hash = {}
    order_created_at_range = order_created_at_start_time..order_created_at_end_time
    MagicBean::Order.where.not(gifts_properties: nil).or(MagicBean::Order.where.not(pool_gifts_properties: nil)).paid.where(created_at: order_created_at_range).ransack({ store_id_eq: options[:store_id] }).result.find_each do |order|
      ((order.gifts_properties || []) + (order.pool_gifts_properties || [])).each do |gift|
        gift_quantity_hash[gift["stock_keeping_unit_id"]] ||= 0
        gift_quantity_hash[gift["stock_keeping_unit_id"]] += gift["quantity"]
      end
    end

    # 计算最近7/14/28天销量
    seven_days_start_at = 7.days.ago.beginning_of_day
    fourteen_days_start_at = 14.days.ago.beginning_of_day
    twenty_eight_days_start_at = 28.days.ago.beginning_of_day
    end_at = Time.current.beginning_of_day
    
    seven_days_sku_sales = MagicBean::OrderItem.where(
      order_id: MagicBean::Order.paid.where(created_at: seven_days_start_at..end_at).ransack({ store_id_eq: options[:store_id] }).result.select(:id),
    ).group(:stock_keeping_unit_id).sum(:quantity)
    
    fourteen_days_sku_sales = MagicBean::OrderItem.where(
      order_id: MagicBean::Order.paid.where(created_at: fourteen_days_start_at..end_at).ransack({ store_id_eq: options[:store_id] }).result.select(:id),
    ).group(:stock_keeping_unit_id).sum(:quantity)

    twenty_eight_days_sku_sales = MagicBean::OrderItem.where(
      order_id: MagicBean::Order.paid.where(created_at: twenty_eight_days_start_at..end_at).ransack({ store_id_eq: options[:store_id] }).result.select(:id),
    ).group(:stock_keeping_unit_id).sum(:quantity)

    avg_sales_header = "#{order_created_at_start_time.strftime("%Y-%m-%d日")}-#{order_created_at_end_time.strftime("%Y-%m-%d日")}平均销量"
    csv_string = CSV.generate(encoding: "UTF-8") do |csv|
      csv << [
        "编号", "货号", "品牌", "产品", "商品名", "一级分类",
        "二级分类", "UPC", "产品状态", "是否上架", "是否特品",
        "营销模式", "是否虚拟商品", "存储方式", "GMV级别", "GP级别", "划线价",
        "售价", "可用库存", "原价预留库存", "OMS待同步WMS库存", "OMS赠品数量", "Runbow庫存", "是否达到补货点",
        "日均销量", "建议补货点", "建议补货上限", "建议补货量", "每箱数量",
        "供应商名称", "供应商价格", "最近7天销量", "最近14天销量", "最近28天销量"
      ]

      @collection.find_each do |sku|
        sku_valid_inventory_dates_count = sku_valid_inventory_dates_hash[sku.id]
        # 日均销量，如果还没记录，日均销量设置为空
        avg_sales_count = sku_valid_inventory_dates_count ? (sku.sales_count / sku_valid_inventory_dates_count.to_f).round(2) : nil

        # 建議補貨點計算方式為：X * 日均銷量
        recommended_restocking_point_count = avg_sales_count ? options[:params]["recommended_restocking_point"] * avg_sales_count : nil
   
        # 建議補貨上限計算方式為：Y * 日均銷量
        recommended_restocking_upper_limit_count = avg_sales_count ? options[:params]["recommended_restocking_upper_limit"] * avg_sales_count : nil
  
        reserved_quantity = reserved_quantity_hash[sku.id].to_i
        # 建議補貨數量計算方式為：建議補貨上限 - 當前可用庫存 (包括原價預留庫存)
        recommended_restocking_count = recommended_restocking_upper_limit_count ? (recommended_restocking_upper_limit_count - sku.quantity - reserved_quantity) : nil
        
        carton_size = sku.carton_size

        on_sale_text = sku.on_sale ? "是" : "否"
        is_special_text = sku.is_special ? "是" : "否"
        marketing_mode_text = I18n.t("activerecord.attributes.magic_bean/stock_keeping_unit/marketing_modes.#{sku.marketing_mode}")
        is_virtual_text = sku.is_virtual ? "是" : "否"
        storage_method_text = I18n.t("activerecord.attributes.magic_bean/item.storage_methods.#{sku.storage_method}")

        # 是否达到补货点: 建议补货点(有小数进一) - OMS可用库存
        restocking_count = (recommended_restocking_point_count || 0).ceil - sku.quantity

        sku_row = [
          sku.id, "SKU: #{sku.no}", sku.brand_name, sku.title, sku.properties_text, sku.parent_category_name,
          sku.category_name, "UPC: #{sku.barcode}", I18n.t("attributes.item/listing_types.#{sku.listing_type}"), on_sale_text, is_special_text,
          marketing_mode_text, is_virtual_text, storage_method_text, sku.gmv_sku_level, sku.gp_sku_level, sku.strikethrough_price_in_yuan,
          sku.price_in_yuan, sku.quantity, reserved_quantity, not_synced_skus_quantity[sku.id].to_i, gift_quantity_hash[sku.id].to_i, sku.wms_inventories.sum(:qty), restocking_count,
          avg_sales_count, recommended_restocking_point_count, recommended_restocking_upper_limit_count, recommended_restocking_count, carton_size,
          sku.newest_supplier_name, sku.newest_supplier_cost_in_yuan, seven_days_sku_sales[sku.id].to_i, fourteen_days_sku_sales[sku.id].to_i, twenty_eight_days_sku_sales[sku.id].to_i
        ]
        csv << sku_row
      end
    end

    csv_string_with_utf8_bom = "\uFEFF" + csv_string

    @subject = "导出商品计划销量列表-#{Time.now.strftime("%Y%m%d%H%M%L")}"
    attachments["#{@subject}.csv"] = csv_string_with_utf8_bom
    mail(
      to: options[:email],
      subject: @subject,
      template_path: "export_mailer",
      template_name: "export"
    )

    decrease_export_list_count
  end

  def sku_in_stock_notice_export(options)
    options, user_ability = before_export(options)
    tmp_params = options[:params]

    pending_notice_hash = nil
    pending_notice_hash = MagicBean::SkuInStockNotice.pending.ransack({ created_at_gteq: tmp_params["notice_created_at_gteq"], created_at_lteq: tmp_params["notice_created_at_lteq"] }).result.group(:stock_keeping_unit_id).count if tmp_params["notice_created_at_gteq"].present? || tmp_params["notice_created_at_lteq"].present?

    csv_string = CSV.generate(encoding: "UTF-8") do |csv|
      csv << %w[标题 主产品分类 次级产品分类 商品货号 到货通知统计]

      MagicBean::StockKeepingUnit.accessible_by(user_ability).ransack(tmp_params.merge(store_id_eq: options[:store_id])).result.find_each do |sku|
        notices_count = if pending_notice_hash
                          pending_notice_hash[sku.id].to_i
                        else
                          sku.pending_in_stock_notices_count
                        end
        csv << [
          sku.human_title,
          sku.item.category_name,
          sku.item.minor_category_name,
          sku.no,
          notices_count
        ]
      end
    end

    csv_string_with_utf8_bom = "\uFEFF" + csv_string

    subject = "导出到货通知统计-#{Time.now.strftime("%Y%m%d%H%M%L")}"
    attachments["#{subject}.csv"] = csv_string_with_utf8_bom
    mail(
      to: options[:email],
      subject: subject,
      template_path: "export_mailer",
      template_name: "export"
    )

    decrease_export_list_count
  end

  def sku_return_export(options)
    options, _ = before_export(options)
    admin_user = MagicBean::AdminUser.find options[:user_id]
    sku_returns_collection(options[:params], options[:order_by], options[:store_id], admin_user)

    csv_string = CSV.generate(encoding: "UTF-8") do |csv|
      csv << %w[product_id 产品id SKU标题 一级分类 二级分类 UPC SKU 退货商品数量 退款金额]

      @collection.find_each do |sku|
        sku_row = [sku.id, sku.item_id, sku.human_title, sku.parent_category_name, sku.category_name, "UPC: #{sku.barcode}", sku.no, sku.sum_after_sale_quantity, sku.sum_after_sale_in_yuan]
        csv << sku_row
      end
    end

    csv_string_with_utf8_bom = "\uFEFF" + csv_string

    @subject = "导出商品退货统计-#{Time.now.strftime("%Y%m%d%H%M%L")}"
    attachments["#{@subject}.csv"] = csv_string_with_utf8_bom
    mail(
      to: options[:email],
      subject: @subject,
      template_path: "export_mailer",
      template_name: "export"
    )

    decrease_export_list_count
  end

  def suppliers_export(options)
    options, _ = before_export(options)

    admin_user = MagicBean::AdminUser.find options[:user_id]
    sales_supplier_collections(options[:params], options[:order_by], options[:store_id])

    csv_string = CSV.generate(encoding: "UTF-8") do |csv|
      csv << %w[product_id 导出编号 货号 商品名 一级分类 分类 UPC 售价 库存 上架时间 供应商价格 供应商 供应商是否包含GST 供应商GST金额]

      @collection.find_each do |sku|
        include_gst_text = sku.newest_supplier_include_gst ? "是" : "否"
        sku_row = [sku.id, "item_no: #{sku.item.no}", "SKU: #{sku.no}", sku.human_title, sku.parent_category_name, sku.category_name, "UPC: #{sku.barcode}", sku.price_in_yuan, sku.quantity, I18n.t("attributes.item/listing_types.#{sku.listing_type}"), sku.newest_supplier_cost_in_yuan, sku.newest_supplier_name, include_gst_text, sku.newest_supplier_gst_amount]
        csv << sku_row
      end
    end

    csv_string_with_utf8_bom = "\uFEFF" + csv_string

    @subject = "导出供应商商品列表-#{Time.now.strftime("%Y%m%d%H%M%L")}"
    attachments["#{@subject}.csv"] = csv_string_with_utf8_bom
    mail(
      to: options[:email],
      subject: @subject,
      template_path: "export_mailer",
      template_name: "export"
    )

    decrease_export_list_count
  end

  # 根据设置发送邮件
  def sku_sales_by_setting(mailer_setting_id)
    mailer_setting = MagicBean::SkuSalesMailerSetting.find(mailer_setting_id)
    delivery_date = Date.current + mailer_setting.deliver_after_n_days.days
    
    # 根据条件查询sku
    skus = if mailer_setting.search_by_conditions?
      condition = mailer_setting.sku_search_conditions
      ransack_params = { item_translated_searchable_title_cont: condition["title_contains"], id_in: target_supplier_ids(condition["supplier_name_contains"]), m: condition["title_and_supplier_name_condition"] }

      where_params = { store_id: mailer_setting.store_id }
      where_params[:is_special] = true if condition["only_special_sku"]
      MagicBean::StockKeepingUnit.where(where_params).ransack(ransack_params).result.ransack(item_ae_drop_shipper_eq: false).result
    else
      MagicBean::StockKeepingUnit.where(id: mailer_setting.sku_ids)
    end.includes(:newest_supplier, item: :translations).order(id: :desc)

    # 统计订单项销量
    target_order_status = [:wait_seller_send_goods, :wait_buyer_confirm_goods, :trade_finished, :buyer_confirm_goods, :apply_refund, :risk_pay, :live_top_confirm]
    order_items_ransack_params = { store_id_eq: mailer_setting.store_id, order_ae_drop_shipper_eq: false, order_status_in: target_order_status, order_delivery_date_eq: delivery_date }
    order_items_hash = MagicBean::OrderItem.where(stock_keeping_unit_id: skus.select(:id)).ransack(order_items_ransack_params).result.group(:stock_keeping_unit_id).sum(:quantity)

    gift_sku_count_hash = {}

    # 全场满赠&优惠池满赠 销量计算
    if mailer_setting.contains_order_pool_gift || mailer_setting.contains_order_gift
      order_ransack_params = { store_id_eq: mailer_setting.store_id, ae_drop_shipper_eq: false, status_in: target_order_status, delivery_date_eq: delivery_date }
      MagicBean::Order.where.not(gifts_properties: nil).or(MagicBean::Order.where.not(pool_gifts_properties: nil)).ransack(order_ransack_params).result.find_each do |order|
        target_gifts = []
        target_gifts += (order.gifts_properties || []) if mailer_setting.contains_order_gift
        target_gifts += (order.pool_gifts_properties || []) if mailer_setting.contains_order_pool_gift
        target_gifts.each do |gift|
          gift_sku_count_hash[gift["stock_keeping_unit_id"]] ||= 0
          gift_sku_count_hash[gift["stock_keeping_unit_id"]] += gift["quantity"]
        end
      end
    end

    # 统计第三方订单销量
    third_party_order_items_hash = {}
    MagicBean::ThirdPartyOrder.shopline.where(store_id: mailer_setting.store_id, delivery_date: delivery_date).find_each do |order|
      order.order_items.each do |order_item|
        # 如果sku为空，则跳过
        next if order_item["sku"].blank?

        third_party_order_items_hash["#{order_item["sku"]}-#{order.store_id}"] ||= 0
        third_party_order_items_hash["#{order_item["sku"]}-#{order.store_id}"] += order_item["quantity"]
      end
    end

    sku_arr = []
    skus.find_each do |sku|
      sales_count = order_items_hash[sku.id].to_i
      gift_count = gift_sku_count_hash[sku.id].to_i
      third_party_sales_count = third_party_order_items_hash["#{sku.no}-#{sku.store_id}"].to_i
      include_gst_text = sku.newest_supplier_include_gst ? "Y" : "N"
      # 跳过销量为0且赠品数量为0的sku
      next if mailer_setting.skip_zero_sales_skus && sales_count.zero? && gift_count.zero? && third_party_sales_count.zero?
      sku_arr << { store_id: sku.store_id, sku_no: sku.no, title: sku.title, properties_text: sku.properties_text, delivery_date: delivery_date.to_s, sales_count: sales_count + gift_count + third_party_sales_count, newest_supplier_cost_in_yuan: sku.newest_supplier_cost_in_yuan, newest_supplier_include_gst: include_gst_text }
    end

    sku_arr.sort_by! { |sku| -sku[:sales_count] }

    headers = %w[店铺ID 货号 标题 规格 发货日期 销量 供应商价格 供应商是否包含GST]

    package = Axlsx::Package.new do |p|
      types = %i[string string string string string integer float string]

      p.workbook.add_worksheet do |sheet|
        sheet.add_row headers

        sku_arr.each do |sku|
          sku_row = [sku[:store_id], sku[:sku_no], sku[:title], sku[:properties_text], sku[:delivery_date], sku[:sales_count], sku[:newest_supplier_cost_in_yuan], sku[:newest_supplier_include_gst]]
          sheet.add_row(sku_row, types: types)
        end
      end
    end

    csv_string = CSV.generate(encoding: "UTF-8") do |csv|
      csv << headers

      sku_arr.each do |sku|
        sku_row = [sku[:store_id], sku[:sku_no], sku[:title], sku[:properties_text], sku[:delivery_date], sku[:sales_count], sku[:newest_supplier_cost_in_yuan], sku[:newest_supplier_include_gst]]
        csv << sku_row
      end
    end

    csv_string_with_utf8_bom = "\uFEFF" + csv_string    

    @subject = mailer_setting.title
    attachments["#{@subject}.csv"] = csv_string_with_utf8_bom
    attachments["#{@subject}.xlsx"] = package.to_stream.read

    mail(
      to: mailer_setting.receiver_emails&.split(/[;；]/)&.map(&:strip),
      cc: mailer_setting.cc_emails&.split(/[;；]/)&.map(&:strip),
      subject: @subject,
      template_path: "export_mailer",
      template_name: "export"
    )
  end

  def notify_price_invalid(emails, sku)
    @sku = sku
    subject = "#{@sku.human_title}售价或新人价有异常"

    mail(
      to: emails,
      subject: subject
    )
  end
end
