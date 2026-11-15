# frozen_string_literal: true

class OrderMailer < ApplicationMailer
  include ::BeansAdmin::Helpers::ExportHelper

  @@export_logger = ::Logger.new("./log/export.log")

  def export(email, order_ids, order_by, stock_keeping_unit_id = nil)
    @@export_logger.info("Orders export: time is #{Time.current}, email is #{email}, order_by is #{order_by}, stock_keeping_unit_id is #{stock_keeping_unit_id}")

    order_by = order_by.is_a?(Array) ? order_by.compact.map(&:strip).join(", ") : order_by.to_s
    order_by = ::BeansAdmin::Helpers::OrderBySanitizer.sanitize(order_by)
    order_by = "created_at desc" if order_by.blank?

    csv_string = CSV.generate(encoding: "UTF-8") do |csv|
      csv << %w[订单ID 订单编号 仓储单号 是否当日达 下单渠道 店铺ID 商品一级分类 商品类目 商品编码 商品名称 商品数量 商品单价 GST% GST 营销模式 总价 支付方式 运费 应收金额 实收金额(AUD) 实收金额(RMB) 手续费(AUD) 退款金额(AUD) 订单最终实付金额(减去退款)AUD 订单最终金额(减去退款)RMB 使用金币数 使用礼品卡金额 优惠券折扣 交易状态 发货方式 是否送货上楼 运费成本 运费备注 买家备注 卖家备注 下单时间 支付时间 发货时间 昵称 手机号 收件人姓名 收件人Email 收件人手机号 UnitNumber StreetNumber Street Suburb State PostalCode 运单号 发票状态]

      # find_each导致order_by失效，这里用each_slice
      MagicBean::Order.where(id: order_ids).includes(:warehouse_order, :logistics, :order_invoice, user: [:member], order_items: [:stock_keeping_unit, { item: [:category, :parent_category] }]).reorder(order_by).each_slice(200) do |slice_orders|
        slice_orders.each do |o|
          payment_in_yuan_aud = o.payment_in_yuan_aud_for_export
          payment_in_yuan_cny = o.payment_in_yuan_cny_for_export
          refunded_amount_in_yuan = o.refunded_amount_in_yuan_num
          without_refunded_amount_aud = payment_in_yuan_aud - refunded_amount_in_yuan
          without_refunded_amount_cny = payment_in_yuan_cny - refunded_amount_in_yuan * o.aud_to_cny_exchange_rate
          invoice_state = o.order_invoice.present? ? I18n.t("activerecord.attributes.magic_bean/order_invoice/states.#{o.order_invoice.state}") : "无发票"

          order_columns = [
            o.amount_in_yuan_num, o.payment_type_name, o.freight_in_yuan_num, o.total_payment_in_yuan_num,
            payment_in_yuan_aud, payment_in_yuan_cny, o.service_amount_aud_for_export, refunded_amount_in_yuan, without_refunded_amount_aud.negative? ? 0 : without_refunded_amount_aud,
            without_refunded_amount_cny.negative? ? 0 : without_refunded_amount_cny,
            o.cost_integral, o.gift_card_amount_in_yuan_num, o.discount_amount_in_yuan_num,
            I18n.t("activerecord.attributes.magic_bean/order.status/#{o.status}"),
            I18n.t("activerecord.attributes.magic_bean/order.delivery_types.#{o.delivery_type}"),
            o.deliver_to_door ? "是" : "否",
            o.freight_cost_in_yuan_num, o.freight_remark,
            o.buyer_message, o.remark, o.created_at&.strftime("%Y-%m-%d %H:%M:%S"), o.paid_at&.strftime("%Y-%m-%d %H:%M:%S"), o.delivered_at&.strftime("%Y-%m-%d %H:%M:%S"),
            o.user_nickname, "+#{o.user_member_mobile}", o.receiver_name, o.receiver_email, "+#{o.receiver_tel_number}", o.receiver_unit_number, o.receiver_street_number, o.receiver_street, o.receiver_city_name, o.receiver_province_name, o.receiver_postal_code,
            o.logistics.map(&:no).join(","), invoice_state
          ]

          order_items = o.order_items
          order_items = order_items.where(stock_keeping_unit_id: stock_keeping_unit_id) if stock_keeping_unit_id
          order_items.each_with_index do |oi, index|
            human_marketing_mode = I18n.t("activerecord.attributes.magic_bean/stock_keeping_unit/marketing_modes.#{oi.marketing_mode}")
            if index == 0
              csv << [o.id, "#{o.short_channel}_#{o.no}", o.warehouse_order_no, o.type == "MagicBean::SameDayDeliveryOrder" ? "是" : "否", o.short_channel, o.store_id, oi.item_parent_category_name, oi.item_category_name, oi.stock_keeping_unit_no, oi.sku_human_title, oi.quantity, oi.real_price_in_yuan_num, "#{oi.gst_percent}%", oi.gst_amount_in_yuan, human_marketing_mode] + order_columns
            else
              csv << [nil, nil, nil, nil, nil, nil, oi.item_parent_category_name, oi.item_category_name, oi.stock_keeping_unit_no, oi.sku_human_title, oi.quantity, oi.real_price_in_yuan_num, "#{oi.gst_percent}%", oi.gst_amount_in_yuan, human_marketing_mode]
            end
          end
        end
      end
    end

    csv_string_with_utf8_bom = "\uFEFF" + csv_string

    @subject = "导出订单-#{Time.current.strftime("%Y-%m-%d-%H-%M")}"
    attachments["#{@subject}.csv"] = csv_string_with_utf8_bom
    mail(
      to: email,
      subject: @subject
    )

    decrease_export_list_count
  end

  def pending_order_receivers
    MagicBean::AdminUser.active.where(receive_notify_email: true).pluck(:email).compact
  end

  def order_analyses_receivers
    MagicBean::SiteConfig.default_config&.order_analyses_notify_emails&.uniq
  end

  def android_sms_receivers
    MagicBean::SiteConfig.default_config&.android_sms_notification_emails&.uniq
  end

  def payment_callback_timeout_receivers
    MagicBean::SiteConfig.default_config&.payment_callback_timeout_emails&.uniq
  end

  def new_order
    @order = params[:order]
    mail(to: pending_order_receivers, subject: "[eBest #{Rails.env} 通知] 新订单") if pending_order_receivers.present?
  end

  def shopline_order_paid
    @order = params[:order]
    @order_email = @order.receiver_properties["email"]
    subject = @order.self_pick? ? "Self-Pickup Date Notification" : "Shipping Date Notification"
    mail(to: @order_email, subject: subject) if @order_email.present?
  end

  def shopline_order_deliver
    @order = params[:order]
    @order_email = @order.receiver_properties["email"]
    store_name = @order.peti_store? ? "Peti" : "eBest"
    subject = @order.self_pick? ? "Your #{store_name} Order is Ready for Pickup!" : "Your #{store_name} Order is On Its Way! Track Your Delivery 🚚"

    mail(to: @order_email, subject: subject) if @order_email.present?
  end

  def apply_refund
    @order = params[:order]
    mail(to: pending_order_receivers, subject: "[eBest #{Rails.env} 通知] 申请退款") if pending_order_receivers.present?
  end

  def sku_notify
    @order = MagicBean::Order.find_by(id: params[:order_id])
    @sku_messages = params[:sku_messages]
    mail(to: params[:emails], subject: "[eBest #{Rails.env} 通知] 订单商品库存通知") if params[:emails].present?
  end

  def order_analyses
    mail(to: order_analyses_receivers, subject: "[eBest #{Rails.env} 通知] #{Time.current.yesterday.strftime("%Y-%m-%d")}订单情况") if order_analyses_receivers.present?
  end

  def android_sms_fail
    @mobile = params[:mobile]
    @message = params[:message]
    @fail_message = params[:fail_message]
    mail(to: android_sms_receivers, subject: "[eBest #{Rails.env} 通知] #{Time.current.strftime("%Y-%m-%d")}安卓短信发送失败") if android_sms_receivers.present?
  end

  def order_close_before_omipay_callback
    @order_no = params[:order_no]
    subject = <<-eos
      [eBest #{Rails.env} 通知]
      #{Time.current.strftime("%Y-%m-%d")}
      Omipay 支付成功回调超时告警
    eos

    mail(to: payment_callback_timeout_receivers, subject: subject)
  end

  def order_close_before_supay_callback
    @order_no = params[:order_no]
    subject = <<-eos
      [eBest #{Rails.env} 通知]
      #{Time.current.strftime("%Y-%m-%d")}
      Supay 支付成功回调超时告警
    eos

    mail(to: payment_callback_timeout_receivers, subject: subject)
  end

  def order_close_before_stripe_callback
    @order_no = params[:order_no]
    subject = <<-eos
      [eBest #{Rails.env} 通知]
      #{Time.current.strftime("%Y-%m-%d")}
      Stripe 支付成功回调超时告警
    eos

    mail(to: payment_callback_timeout_receivers, subject: subject)
  end

  def order_close_before_cba_risk_callback
    @order_no = params[:order_no]
    subject = <<-eos
      [eBest #{Rails.env} 通知]
      #{Time.current.strftime("%Y-%m-%d")}
      CBA 风险支付成功回调超时告警
    eos

    mail(to: payment_callback_timeout_receivers, subject: subject)
  end

  def order_close_before_cba_callback
    @order_no = params[:order_no]
    subject = <<-eos
      [eBest #{Rails.env} 通知]
      #{Time.current.strftime("%Y-%m-%d")}
      CBA 支付成功回调超时告警
    eos

    mail(to: payment_callback_timeout_receivers, subject: subject)
  end

  def member_orders_export(email)
    package = Axlsx::Package.new do |p|
      headers = %w[用户编号 用户昵称 手机号 邀请会员数量 订单编码 订单金额 订单创建时间]
      types = %i[string string string integer string string string]

      p.workbook.add_worksheet do |sheet|
        sheet.add_row headers

        MagicBean::Order.includes([user: [member: :invitees]]).paid.order("user_id desc, created_at desc").each do |order|
          row = [order.user_id, order.user.nickname, order.user.member.mobile, order.user.member.invitees.size, order.no, "$#{order.total_payment_in_yuan}", order.created_at.strftime("%Y-%m-%d %H:%M:%S")]
          sheet.add_row(row, types: types)
        end
      end
    end

    @subject = "会员订单-#{Time.current.strftime("%Y-%m-%d-%H-%M")}"
    attachments["#{@subject}.xlsx"] = package.to_stream.read
    mail(
      to: email,
      subject: @subject
    )
  end

  def analysis_by_date(email, start_date, end_date)
    start_at = start_date.in_time_zone.beginning_of_day
    end_at = end_date.in_time_zone.end_of_day

    app_uvs = MagicBean::History.app.where(operator_type: "MagicBean::User", created_at: start_at..end_at).group("CAST(created_at AS DATE)").distinct.count(:operator_id)
    mini_program_uvs = MagicBean::History.mini_program.where(operator_type: "MagicBean::User", created_at: start_at..end_at).group("CAST(created_at AS DATE)").distinct.count(:operator_id)
    app_pvs = MagicBean::History.app.where(operatable_type: "MagicBean::CustomPage", params: [{"en_name"=>"home_v2"}, {"en_name"=>"home"}], created_at: start_at..end_at).group("CAST(created_at AS DATE)").count
    mini_program_pvs = MagicBean::History.mini_program.where(operatable_type: "MagicBean::CustomPage", params: {"en_name"=>"home"}, created_at: start_at..end_at).group("CAST(created_at AS DATE)").count
    app_orders = MagicBean::Order.paid.app.where(created_at: start_at..end_at).group("CAST(created_at AS DATE)").count
    mini_program_orders = MagicBean::Order.paid.mini_program.where(created_at: start_at..end_at).group("CAST(created_at AS DATE)").count
    app_user_orders = MagicBean::Order.paid.app.where(created_at: start_at..end_at).group("CAST(created_at AS DATE)").distinct.count(:user_id)
    mini_program_user_orders = MagicBean::Order.paid.mini_program.where(created_at: start_at..end_at).group("CAST(created_at AS DATE)").distinct.count(:user_id)

    package = Axlsx::Package.new do |p|
      headers = %w[日期 访问人数(APP) 访问人数(小程序) 访问次数(APP) 访问次数(小程序) 订单数(APP) 订单数(小程序) 下单人数(APP) 下单人数(小程序)]
      types = %i[string integer integer integer integer integer integer integer]

      p.workbook.add_worksheet do |sheet|
        sheet.add_row headers
        (start_date..end_date).each do |day|
          row = [day, app_uvs[day], mini_program_uvs[day], app_pvs[day], mini_program_pvs[day], app_orders[day], mini_program_orders[day], app_user_orders[day], mini_program_user_orders[day]]
          sheet.add_row(row, types: types)
        end
      end
    end

    @subject = "每日订单数据统计-#{Time.current.strftime("%Y-%m-%d-%H-%M")}"
    attachments["#{@subject}.xlsx"] = package.to_stream.read
    mail(
      to: email,
      subject: @subject
    )
  end

  def week_gift_data
    end_date = Date.current.yesterday
    start_date = end_date - 6.days

    time_range = (start_date.to_date.beginning_of_day)..(end_date.to_date.end_of_day)
    collection = MagicBean::Order.includes(:store).paid.where(created_at: time_range).where.not(gifts_properties: nil).order(:created_at)

    hash = {}

    collection.each do |order|
      order.gifts_properties.each do |gift|
        order_date = order.created_at.to_date
        hash_key = "#{order_date}_#{gift["stock_keeping_unit_id"]}"
        hash[hash_key] ||= gift.merge({ order_date: order_date, gift_count: 0 })
        hash[hash_key][:gift_count] += gift["quantity"]
        hash[hash_key][:store_name] = order.store.name
      end
    end

    csv_string = CSV.generate(encoding: "UTF-8") do |csv|
      csv << %w[门店 下单日期 赠品名称 赠品sku 赠品单价 赠品数量]
      hash.values.each do |gift_value|
        csv << [gift_value[:store_name], gift_value[:order_date], "#{gift_value["title"]} - #{gift_value["properties_text"]}", gift_value["no"], gift_value["price_in_yuan"], gift_value[:gift_count]]
      end
    end
    csv_string_with_utf8_bom = "\uFEFF" + csv_string

    @subject = "赠品每周统计-#{start_date}-to-#{end_date}"
    attachments["#{@subject}.csv"] = csv_string_with_utf8_bom
    mail(
      to: "yanan.z@ebest.com.au",
      subject: @subject,
      template_path: "export_mailer",
      template_name: "export"
    )
  end

  def member_order_data_export_by_date(date, email)
    members = MagicBean::Member.includes(:inviter, [user: :selected_store]).where("CAST(created_at AS DATE) = ?", date).order(:id)

    csv_string = CSV.generate(encoding: "UTF-8") do |csv|
      csv << %w[注册日期 手机号 邀请人手机号 所属门店 目前已下订单数]

      members.each do |member|
        orders_count = member.user.orders.paid.count
        csv << [member.created_at.to_date, member.mobile, member.inviter&.mobile, member.user&.selected_store&.name, orders_count]
      end
    end
    csv_string_with_utf8_bom = "\uFEFF" + csv_string

    @subject = "每日会员数据统计-#{date}"
    attachments["#{@subject}.csv"] = csv_string_with_utf8_bom

    mail(
      to: email,
      subject: @subject,
      template_path: "export_mailer",
      template_name: "export"
    )
  end
end
