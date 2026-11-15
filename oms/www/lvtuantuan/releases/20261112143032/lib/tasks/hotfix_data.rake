# frozen_string_literal: true

namespace :hotfix do
  desc "持久化订单项的实际单价"
  task hotfix_order_items_real_price_persistence: :environment do
    MagicBean::OrderItem.find_each do |oi|
      oi.calculate_real_price
      oi.save(validate: false)
    end
  end

  desc "移除产品导入编号空格"
  task remove_item_no_spaces: :environment do
    MagicBean::Item.where("no LIKE ?", "% %").find_each do |item|
      no = item.no.strip
      item.update_columns(no: no) unless MagicBean::Item.where(no: no).exists?
    end
  end

  desc "remove useless coupon codes"
  task remove_useless_coupon_codes: :environment do
    MagicBean::CouponTemplate.find_each do |t|
      t.coupon_codes.clear
      t.coupon_codes << t.coupons.assignable.pluck(:code)
    end

    MagicBean::Coupon.where("expired_at < ? AND status = 1", Time.current).find_each do |coupon|
      coupon.expired!
      coupon.delete_from_redis unless coupon.received?
    end
  end

  desc "change address's province_name to province short name"
  task change_province_name_to_province_short_name: :environment do
    MagicBean::Address.find_each do |address|
      address.province_name = MagicBean::Address::REGION_NAME_HASH[address.province_name]
      address.save(validate: false) if address.province_name.present?
    end
  end

  desc "recalculate order actually_amount_in_cent"
  task recalculate_order_actually_amount: :environment do
    MagicBean::Order.paid.each do |order|
      refund_amount_in_cent = order.payments.refund_payment_type.completed.sum(:amount_in_cent)
      after_sale_amount_in_cent = order.after_sales.finished.sum(:amount_in_cent)
      if refund_amount_in_cent + order.actually_amount_in_cent + after_sale_amount_in_cent != order.payment_in_cent
        recalculate_actually_amount_in_cent = order.payment_in_cent - refund_amount_in_cent - after_sale_amount_in_cent
        order.update_columns(actually_amount_in_cent: recalculate_actually_amount_in_cent)
      end
    end
  end

  desc "set orders default integral values"
  task set_orders_default_integral_values: :environment do
    default_site_config = MagicBean::SiteConfig.default_config
    MagicBean::Order.update_all(
      integral_deducted_from_one_yuan: default_site_config&.integral_deducted_from_one_yuan,
      integral_received_from_one_yuan: default_site_config&.integral_received_from_one_yuan
    )
  end

  desc "set omipay payment platform"
  task set_omipay_payment_platform: :environment do
    MagicBean::OmipayPayment.charge_payment_type.each do |payment|
      next if payment.platform.present?
      result = Omipay::Api.get_order(payment.transaction_id)
      # 如果是支付宝支付，返回为"ALIPAY-ONLINE"，跟传给omipay的参数不一致
      platform = result["platform"] == "ALIPAY-ONLINE" ? MagicBean::OmipayPayment::ALIPAY_PLATFORM : result["platform"]
      payment.update_columns(platform: platform)
      payment.order.update_columns(omipay_platform: platform)
    end
  end

  desc "calculate order items real price"
  task :calculate_order_items_real_price, [:date] => :environment do |t, args|
    date = args[:date]&.in_time_zone(Time.zone.name)
    MagicBean::Order.where("paid_at > ?", date).each do |order|
      order.order_items.each do |item|
        item.calculate_real_price
        item.calculate_display_price
        item.save(validate: false, touch: false)
      end
    end
  end

  desc "update item sales_count"
  task update_item_sales_count: :environment do
    MagicBean::Item.transaction do
      MagicBean::Item.select("items.*, COALESCE(SUM(order_items.quantity), 0) AS calculate_sales_count").left_joins({order_items: :order}).where("orders.status IN (2,3,5,7,8)").group(:id).each do |item|
        next if item.sales_count == item.calculate_sales_count
        item.calculate_actual_monthly_sales_count
        item.sales_count = item.calculate_sales_count
        item.save!
      end
    end
  end

  desc "update no callback omipay order"
  task :update_no_callback_omipay_order, [:id] => :environment do |t, args|
    order = MagicBean::Order.find_by id: args[:id]
    abort("只可处理已关闭订单") unless order && order.trade_closed?

    result = ::Omipay::Api.get_order(order.omipay_transaction_id)
    abort("只可处理已支付订单") unless result["return_code"] == "SUCCESS" && result["result_code"] == "PAID"

    payment = MagicBean::OmipayPayment.find_or_create_charge_when_no_callback(order, result, order.channel)
    # 触发退款，已经退款的payment不再重复触发
    payment.generate_refund_payment(payment.amount_in_cent, order, true, true, true, true) unless payment.payments.refund_payment_type.exists?
  end

  desc "CBA payment no callback"
  task :update_no_callback_CBA_order, [:no, :transaction_id] => :environment do |t, args|
    order = MagicBean::Order.find_by no: args[:no]

    return if order.blank?

    resp = Commweb::Payment.retrieve_transaction(order.no, args[:transaction_id], order.channel)

    if resp["order"]["status"] == "CAPTURED"
      payment = MagicBean::CommwebPayment.find_or_create_charge_from_webhook(order, resp, order.channel)
      total_captured_amount_in_cent = (resp["order"]["totalCapturedAmount"] * 100).round
      net_amount_in_cent = payment.paymentable.payment_in_cent
      service_amount_in_cent = total_captured_amount_in_cent - net_amount_in_cent
      credit_card_percentage = (service_amount_in_cent * 100 / net_amount_in_cent.to_f).round(2)

      ActiveRecord::Base.transaction do
        payment.update!(
          response: resp,
          status: :completed,
          amount_in_cent: total_captured_amount_in_cent,
          service_amount_in_cent: service_amount_in_cent,
          completed_at: resp["order"]["lastUpdatedTime"].in_time_zone(MagicBean::CommwebPayment::TIME_ZONE)
        )

        order.set_order_items_service_amount(service_amount_in_cent)

        if order.trade_closed?
          order.update!(paid_at: payment.completed_at,
                        final_amount_in_cent: total_captured_amount_in_cent,
                        integral_received_from_one_yuan: order.calculate_integral_received_from_one_yuan,
                        actual_credit_card_service_percentage: credit_card_percentage,
                        actual_credit_card_service_amount_in_cent: service_amount_in_cent)
          # 触发退款，已经退款的payment不再重复触发
          payment.generate_refund_payment(payment.amount_in_cent, order, true, true, true, true) unless payment.payments.refund_payment_type.exists?
        else
          order.pay!
          order.update!(paid_at: payment.completed_at,
                        final_amount_in_cent: total_captured_amount_in_cent,
                        actual_credit_card_service_percentage: credit_card_percentage,
                        actual_credit_card_service_amount_in_cent: service_amount_in_cent)
        end
      end
    end
  end

  desc "Remove duplicative shopping_cart"
  task remove_duplicative_shopping_cart: :environment do
    ActiveRecord::Base.transaction do
      MagicBean::ShoppingCart.all.group(:user_id).having("count(id) > 1").count.each do |user_id, _|
        carts = MagicBean::ShoppingCart.where(user_id: user_id).order(:id)
        # 保留最新创建的购物车
        first_cart = carts.last
        carts[0..-2].each do |cart|
          cart.shopping_cart_items.update_all(shopping_cart_id: first_cart.id)
          cart.destroy!
        end
      end
    end
  end

  desc "Omipay退款有时没回调，但退款成功了，需要处理订单"
  task :update_omipay_refund_order, [:refund_payment_id] => :environment do |t, args|
    refund_payment = MagicBean::OmipayPayment.find_by id: args[:refund_payment_id]
    return if refund_payment.blank?
    refund_payment.refund_query_by_order_no
  end

  desc "设置 CustomPage 缓存"
  task set_redis_content_of_custom_pages: :environment do
    MagicBean::CustomPage.find_each do |page|
      page.send :update_redis_content
    end
    puts "done"
  end

  desc "初始化用户未读消息数记录"
  task initialize_message_unread_counters: :environment do
    MagicBean::User.find_each do |user|
      user.send :init_message_unread_counter
    end
    puts "done"
  end

  desc "为商品补充一级分类"
  task set_parent_category_for_items: :environment do
    MagicBean::Item.find_each do |item|
      category = item.category
      if category.present?
        item.update_attribute :parent_category_id, category.parent_id
      end
    end
    puts "Done"
  end

  desc "初始化固定时间coupon_template的expired job"
  task expired_fixed_period_coupons: :environment do
    MagicBean::CouponTemplate.fixed_period.active.each do |template|
      template.send :enqueue_expired_fixed_period_coupons_Job
    end
  end

  desc "初始化SetOrderConfirmedJob"
  task init_order_comfirm_job: :environment do
    store_id = MagicBean::Store.find_by(name: "Sydney")&.id
    return if store_id.blank?
    MagicBean::Order.paid.pending.where("store_id = ? AND delivery_date >= ?", store_id, Date.tomorrow).where.not(delivery_type: "virtual_delivery").each do |order|
      order.send :enqueue_set_order_confirmed_job
    end
  end

  desc "初始化优惠券缓存"
  task :init_coupon_codes_redis, [:coupon_template_id] => :environment do |t, args|
    coupon_template = MagicBean::CouponTemplate.find args[:coupon_template_id]
    coupon_template.push_coupon_codes_to_redis(coupon_template.coupons.pending)
  end

  desc "初始化自动确认订单job"
  # date_string为redis出异常当天日期
  task :init_confirm_order_job, [:date_string] => :environment do |t, args|
    end_date = args[:date_string].to_date
    start_date = end_date - 14.days
    MagicBean::Order.wait_buyer_confirm_goods.where(delivered_at: start_date.beginning_of_day..end_date.end_of_day).each do |order|
      ConfirmOrderJob.set(wait_until: order.delivered_at + MagicBean::Order::CONFIRM_GOODS_TIME).perform_later(order.id)
    end
  end

  desc "初始化自动完成订单job"
  # date_string为redis出异常当天日期
  task :init_finish_order_job, [:date_string] => :environment do |t, args|
    end_date = args[:date_string].to_date
    start_date = end_date - 14.days
    MagicBean::Order.buyer_confirm_goods.where(confirmed_at: start_date.beginning_of_day..end_date.end_of_day).each do |order|
      FinishOrderJob.set(wait_until: order.confirmed_at + MagicBean::Order::FINISH_ORDER_TIME).perform_later(order.id)
    end
  end

  desc "已收货订单发放优惠券"
  # time_string传部署前1分钟的北京时间，格式为 2022-01-17 18:00
  task :assign_gift_coupon, [:time_string] => :environment do |t, args|
    time = args[:time_string].in_time_zone("Beijing")

    MagicBean::Order.buyer_confirm_goods.where("confirmed_at <= ?", time).where.not(gift_coupon_template_id: nil).each do |order|
      order.send :generate_and_assign_gift_coupon_to_user
    end
  end

  desc "更新自定义页面小程序码"
  task update_custom_page_qrcodes: :environment do |t, args|
    MagicBean::CustomPage.where(is_aus_qrcode: false).each do |page|
      page.send :enqueue_generate_qrcode_job, MagicBean::CustomPage::QRCODE_WIDTH
    end
  end

  desc "批量复制悉尼产品到布里斯班"
  # sku库存全部设置为0
  # 用户评论、用户收藏记录、月销量、售后统计等数据不需要同步，同时不需要限购的设置，还有截单和预售的设置
  # 只复制立即上架售卖和自定义上架时间售卖的产品
  task batch_copy_items: :environment do |t, args|
    sydney_store = MagicBean::Store.sydney
    brisbane_store = MagicBean::Store.find_by name: "Brisbane"
    return if sydney_store.blank? || brisbane_store.blank?

    brisbane_self_pick_tempate_id = brisbane_store.freight_templates.self_pick.first&.id
    brisbane_merchant_delivery_tempate_id = brisbane_store.freight_templates.merchant_delivery.first&.id

    MagicBean::Item.where(store_id: sydney_store.id, listing_type: [:online, :advance_on]).where.not(product_id: MagicBean::Item.where(store_id: brisbane_store.id).select(:product_id)).each do |target_item|
      item = target_item.dup
      item.no = nil
      item.tag_list = target_item.tag_list
      item.sales_count = 0
      item.likes_count = 0
      item.comments_count = 0
      item.delivery_type = (target_item.delivery_type || []) - ["express"]
      item.store_id = brisbane_store.id
      item.qrcode = nil
      item.listing_type = "pending"
      item.default_freight_template_ids = [brisbane_merchant_delivery_tempate_id, brisbane_self_pick_tempate_id].compact
      item.start_selling_at = nil
      item.is_presell = false
      item.presell_dispatch_on = nil
      item.presell_end_at = nil
      item.latest_presell_dispatch_on = nil
      item.buy_quota_days = nil
      item.buy_quota = 0

      item.stock_keeping_units << target_item.stock_keeping_units.map do |v|
        v.dup.tap do |sku|
          sku.comments_count = 0
          sku.quantity = 0
        end
      end

      item.save
    end
  end

  desc "根据答疑&保障设置部分商品的存储方式"
  task set_storage_method_of_items_based_on_qa_and_guarantee: :environment do
    unless Rails.env.production?
      puts "Only run this task on production"
      next
    end

    # 正式环境答疑&保障：
    #   “冷藏” ID：14
    #   “冷冻” ID：15
    MagicBean::Item.where(qa_and_guarantee_id: 14).update_all(storage_method: :refrigerated_storage)
    MagicBean::Item.where(qa_and_guarantee_id: 15).update_all(storage_method: :frozen_storage)
  end

  desc "将订单从待发货改为待收货状态"
  task :deliver_order, [:id] => :environment do |t, args|
    order = MagicBean::Order.find_by id: args[:id]
    return unless order
    order.logistics.create(company: "eParcel")
    order.update_columns(status: :wait_buyer_confirm_goods, sync_status: :synced)
    order.send(:update_delivered_at)
    order.send(:enqueue_confirm_goods_job)
  end

  desc "将已存在的限时优惠改为已完成"
  task finish_existing_time_limited_promotions: :environment do
    MagicBean::TimeLimitedPromotion.pending.update_all(state: :finished)
  end

  desc "更新item parent_category_id"
  task batch_update_item_parent_category_id: :environment do
    MagicBean::Item.includes(:category).where.not(category_id: nil).each do |item|
      # 测试环境有category_id存在但无对应分类情况
      next unless item.category
      parent_id = item.category.parent_id
      item.update_columns(parent_category_id: parent_id) if parent_id != item.parent_category_id
    end
  end

  desc "删除购物车重复商品"
  task delete_duplicate_shopping_cart_items: :environment do
    cart_ids = MagicBean::ShoppingCartItem.with_deleted.pluck(:shopping_cart_id).uniq
    cart_ids.each do |cart_id|
      hash = {}
      MagicBean::ShoppingCartItem.with_deleted.where(shopping_cart_id: cart_id).each do |cart_item|
        key = [cart_item.shopping_cart_id, cart_item.stock_keeping_unit_id].join("-")
        hash[key] ||= []
        hash[key] << cart_item
      end

      duplicated = hash.select { |key, arr| arr.size > 1 }

      next if duplicated.empty?

      duplicated.each_value do |arr|
        arr.shift
        arr.each do |elem|
          puts "Destroying ShoppingCartItem #{elem.id}"
          elem.really_destroy!
        end
      end
    end
  end

  desc "年末清除2021年未使用积分"
  task clear_last_year_integral: :environment do
    this_year_start_time = "2022-01-01".in_time_zone(ApplicationRecord::TIME_ZONE)
    this_year_end_time = this_year_start_time.end_of_year

    # 由于订单发放积分已关闭，把用户冻结积分清零的话
    # 虽然有部分订单一直处于待发货状态，这些订单变为已完成会相应的减去冻结积分，会导致member冻结积分变为负数，不过在减冻结积分那里增加了逻辑判断，所以不会影响后续流程
    MagicBean::Member.update_all(app_blocked_integral: 0)

    MagicBean::Member.includes(:user).all.each do |member|
      # 用户在2022年总共使用的积分总数
      cost_integral = member.integral_records.app.where(kind: [:spent, :spent_return], created_at: this_year_start_time..this_year_end_time).sum(:integral)
      # 用户在2021年底的可用积分数
      last_year_available_integral = member.integral_records.app.where("created_at < ?", this_year_start_time).order(id: :desc).first&.available_integral.to_i

      # 用户上一年剩余积分 大于 今年的使用积分，则积分要做扣除
      if cost_integral.abs < last_year_available_integral
        member.with_lock do
          expired_integral = last_year_available_integral - cost_integral.abs
          expired_integral = [member.app_available_integral, expired_integral].min
          available_integral = member.app_available_integral - expired_integral

          member.update(app_available_integral: available_integral)

          member.create_integral_record(:integral_expired, nil, "app", expired_integral)
        end
      end
    end
  end

  desc "回收拉黑用户积分"
  task recycle_blocked_members_integral: :environment do
    MagicBean::Member.ransack({ user_is_blocked_eq: true }).result.each do |member|
      member.with_lock do
        recycle_integral = member.app_available_integral
        member.update(app_available_integral: 0, app_blocked_integral: 0)
        next if recycle_integral.zero?
        member.create_integral_record(:recycle, nil, "app", recycle_integral)
      end
    end
  end

  desc "补充中奖用户的直播间ID"
  task add_live_room_id_to_lottery_winning_users: :environment do
    MagicBean::LiveRoomLotteryWinningUser.includes(:live_room_lottery).find_each do |user|
      user.update_attribute :live_room_id, user.live_room_lottery.live_room_id
    end
  end

  desc "补回已结束限时优惠库存更新时间"
  task add_quantity_updated_at_to_finished_promotions: :environment do
    MagicBean::TimeLimitedPromotion.includes(:time_limited_promotion_prices).where.not(state: :pending).find_each do |prom|
      prom.time_limited_promotion_prices.update_all(quantity_updated_at: prom.start_at)
    end
  end

  desc "触发已经填写过生日的会员发生日奖励任务"
  task init_member_reward_birthday_job: :environment do
    MagicBean::Member.where.not(birthday: nil).each do |member|
      member.send :enqueue_reward_birthday_job
    end
  end

  desc "自动补全优惠券模板英文名"
  task init_coupon_templates_title_en_job: :environment do
    MagicBean::CouponTemplate.includes(:translations).all.find_each do |template|
      next if template.title_en.present?
      template.send :set_title_i18n
      template.save(validate: false)
    end
  end

  desc "补充直播间订单数据"
  task add_live_room_orders: :environment do
    MagicBean::LiveRoom.finished_state.find_each do |live_room|
      live_room.generate_live_orders
    end
  end

  desc "初始化所有已填写生日用户发放生日奖励job"
  task init_member_birthday_reward_job: :environment do
    error_ids = []

    MagicBean::Member.where.not(birthday: nil).each do |member|
      begin
        member.send :enqueue_reward_birthday_job
      rescue => _
        error_ids << member.id
      end
    end

    puts "未初始化会员id: #{error_ids.join(", ")}"
  end

  desc "特殊运费模板导入地区"
  task freight_template_import_suburbs: :environment do
    name_zh_cn = "特殊地区$25固定运费"
    name_zh_tw = "特殊地區$25固定運費"
    name_en = "Special area $25 flat shipping fee"

    express_template = MagicBean::DefaultFreightTemplate.find 1

    exceptional_template = express_template.exceptional_freight_templates.ransack({translations_name_cont: name_zh_cn}).result.last

    exceptional_template = express_template.exceptional_freight_templates.new(
      first_kg_charge_in_cent: 2500,
      second_kg_charge_in_cent: 2500,
      continued_weight_charge_in_cent: 0,
      extra_charge_in_cent: 0,
      free_shipping_amount_in_cent: nil,
      first_kg_cost_in_cent: 2500,
      second_kg_cost_in_cent: 2500,
      continued_weight_cost_in_cent: 0,
      extra_cost_in_cent: 0,
      store_id: express_template.store_id,
      app_free_shipping_amount_in_cent: nil,
      web_free_shipping_amount_in_cent: nil,
      mini_program_free_shipping_amount_in_cent: nil,
      name_zh_cn: name_zh_cn,
      name_zh_tw: name_zh_tw,
      name_en: name_en,
    ) unless exceptional_template

    au_suburb_ids = []

    CSV.foreach(Rails.root.join("tmp", "freight.csv"), headers: true) do |row|
      au_suburb_ids += MagicBean::AuSuburb.where(state_short_name: row["state"], postal_code: row["code"]).ids
    end

    exceptional_template.au_suburb_ids = au_suburb_ids
    exceptional_template.save!
  end

  desc "Add order channel permissions to admin users"
  task add_order_channel_permissions_to_admin_users: :environment do
    MagicBean::AdminUser.find_each do |admin_user|
      order_permissions = %w[normal_orders auction_orders groupon_orders same_day_delivery_orders virtual_orders ae_orders]
      has_order_permission = (admin_user.permissions & order_permissions).any?
      order_channel_permission = MagicBean::Order::CHANNEL_PERMISSION_MAPPING.keys

      if has_order_permission
        admin_user.permissions = admin_user.permissions + order_channel_permission
        admin_user.save
      end
    end
  end

  desc "Init first sale at for skus"
  task init_first_sale_at_for_skus: :environment do
    MagicBean::StockKeepingUnit.find_each do |sku|
      sku.update_column :first_sale_at, sku.created_at
    end
  end

  desc "Init first sale at for items"
  task init_first_sale_at_for_items: :environment do
    MagicBean::Item.includes(:stock_keeping_units).find_each do |item|
      # 避免n+1问题导致处理太久，这里不用minimum
      first_sale_at = item.stock_keeping_units.map(&:first_sale_at).compact.min
      item.update_column :first_sale_at, first_sale_at
    end
  end

  desc "导出悉尼时间段内每一天的配送量，按Suburb区分"
  task export_sydney_delivery_count_by_suburb: :environment do
    # 先不做成参数，后面有特殊应用到再弄
    start_date = "2023-04-01"
    end_date = "2023-06-30"
    hash = {}
    MagicBean::Order.where(store_id: 2).paid.merchant_delivery.where("delivery_date between ? and ?", start_date, end_date).order(:delivery_date).each do |order|
      hash[order.receiver_city_name.downcase] ||= {}
      hash[order.receiver_city_name.downcase][order.delivery_date] ||= 0
      hash[order.receiver_city_name.downcase][order.delivery_date] += 1
    end

    output_filename = Rails.root.join("tmp", "suburb-delivery-dates-#{start_date.strftime(date_format)}-to-#{end_date.strftime(date_format)}.csv")

    CSV.open(output_filename, "w", write_headers: true, headers: ["Suburb", "日期", "配送量"]) do |csv|
      hash.each do |suburb, dates_data|
        dates_data.each do |delivery_date, count|
          csv << [suburb, delivery_date, count]
        end
      end
    end
    puts "done", output_filename
  end

  desc "计算三个月内订单金币、积分、手续费，分摊到订单项"
  task calculate_order_items_multiple_columns_amount: :environment do
    MagicBean::Order.paid.where("created_at > ?", 3.months.ago).find_each do |order|
      # 微信支付的手续费没有保存到order，需要从payment中获取
      service_amount = order.payment_type == "wechat" ? order.completed_charge_payment&.service_amount_in_cent.to_i : order.service_amount_aud_in_cent
      # 如果金币、手续费、积分都为0，则跳过
      next if service_amount.zero? && order.cost_integral.zero? && order.gift_card_amount_in_cent.zero?
      
      order.set_order_items_gift_card_amount
      order.set_order_items_cost_integral
      order.set_order_items_service_amount(service_amount)
      order.save(validate: false)
    end

    MagicBean::AfterSale.includes(:order_items).where("created_at > ?", 3.months.ago).find_each do |after_sale|      
      # 旧退款仍不退手续费，这里只是把对应的值都计算，不是真正退的金额
      after_sale.sort_order_items_by_amount.each do |after_sales_order_item|
        order_item = after_sales_order_item.order_item
        real_amount = after_sales_order_item.real_price_in_cent * after_sales_order_item.quantity
        service_amount = (order_item.service_amount_in_cent * after_sales_order_item.quantity / order_item.quantity.to_f).floor
        cost_integral = (order_item.cost_integral * after_sales_order_item.quantity / order_item.quantity.to_f).floor
        gift_card_amount = (order_item.gift_card_amount_in_cent * after_sales_order_item.quantity / order_item.quantity.to_f).floor
        cash_amount = real_amount - gift_card_amount - after_sales_order_item.after_sale.send(:exchange_integral_to_aus_dollar, cost_integral)

        after_sales_order_item.real_amount_in_cent = real_amount
        after_sales_order_item.service_amount_in_cent = service_amount
        after_sales_order_item.cost_integral = cost_integral
        after_sales_order_item.gift_card_amount_in_cent = gift_card_amount
        after_sales_order_item.cash_amount_in_cent = cash_amount
        after_sales_order_item.max_service_amount_in_cent = service_amount
        after_sales_order_item.max_cost_integral = cost_integral
        after_sales_order_item.max_gift_card_amount_in_cent = gift_card_amount
        after_sales_order_item.max_cash_amount_in_cent = cash_amount
        after_sales_order_item.original_real_amount_in_cent = real_amount
      end

      after_sale.save(validate: false)
    end
  end

  desc "同步所有已订阅的邮箱到Sendgrid"
  task sync_subscribed_emails_to_sendgrid: :environment do
    list_id = Rails.application.credentials.dig(Rails.env.to_sym, :sendgrid, :list_id)
    MagicBean::Member.where(receive_activity_email: true).where.not(email: nil).each_slice(200) do |members|
      contacts = members.map { |member| { email: member.email, first_name: member.first_name, last_name: member.last_name } }

      data = {
        list_ids: [list_id],
        contacts: contacts
      }
      
      SendGridApi.client.marketing.contacts.put(request_body: data)
    end
  end

  desc "处理使用相同优惠券的订单数据"
  task update_orders_duplicate_coupon: :environment do
    duplicate_coupon_hash = MagicBean::Order.where.not(status: :trade_closed, coupon_id: nil).group(:coupon_id).having("count(*) >1").count

    duplicate_coupon_hash.each do |coupon_id, count|
      MagicBean::Order.where(coupon_id: coupon_id).where.not(status: :trade_closed).limit(count - 1).update_all(coupon_id: nil)
    end
  end

  task "导出OMS数据库所有文件url"
  task export_all_oms_urls: :environment do
    file_path = Rails.root.join("tmp/oms_oss.jsonl")

    File.open(file_path, "a") do |f|
      after_sale_images = MagicBean::AfterSale.all.map do |after_sale|
        ((after_sale.images || []) + (after_sale.audit_images || []) + [after_sale.audit_video]).compact
      end.flatten.uniq.each do |image|
        f.puts format_image(image).split("?").first
      end

      MagicBean::AgeVerification.all.pluck(:image).uniq.compact.each {|image| f.puts format_image(image).split("?").first }
      MagicBean::AppDownloadChannel.all.pluck(:qrcode).uniq.compact.each {|image| f.puts format_image(image).split("?").first }
      MagicBean::Auction::Activity.all.map do |auction|
        (([auction.cover]) + (auction.detail_images || []) + (auction.main_images || [])).compact
      end.flatten.uniq.each {|image| f.puts format_image(image).split("?").first }
      MagicBean::BannerClick.all.pluck(:url).uniq.compact.each {|image| f.puts format_image(image).split("?").first }
      MagicBean::Brand.all.pluck(:cover).uniq.compact.each {|image| f.puts format_image(image).split("?").first }
      MagicBean::Category.all.map {|cate| [cate.icon, cate.filter_icon]}.flatten.uniq.compact.each {|image| f.puts format_image(image).split("?").first }

      MagicBean::Comment.all.map do |comment|
        ((comment.images || []) + (comment.pictures || []) + [comment.user_avatar]).compact
      end.flatten.uniq.each {|image| f.puts format_image(image).split("?").first }

      MagicBean::CouponPackage.all.pluck(:cover).uniq.compact.each {|image| f.puts format_image(image).split("?").first }

      MagicBean::CouponTemplate.all.map do |c|
        [c.details_image, c.expired_image, c.ticket_image, c.qrcode].compact
      end.flatten.uniq.each {|image| f.puts format_image(image).split("?").first }

      MagicBean::Coupon.all.pluck(:qrcode).uniq.compact.each {|image| f.puts format_image(image).split("?").first }
      MagicBean::CustomList.all.pluck(:icon).uniq.compact.each {|image| f.puts format_image(image).split("?").first }
      MagicBean::CustomPage.all.pluck(:qrcode_url).uniq.compact.each {|image| f.puts format_image(image).split("?").first }

      MagicBean::FormItem.all.map do |item|
        (([item.cover]) + (item.detail_images || []) + (item.main_images || [])).compact
      end.flatten.uniq.each {|image| f.puts format_image(image).split("?").first }

      MagicBean::HomepagePagingSetting.all.map do |page|
        banner_pages = page.banners["data"].map {|data| data["src"]}
        image_notice = page.image_notice["data"]&.dig("leftSideImage")
        ([page.image, page.background_image, page.selected_image, image_notice] + banner_pages).compact
      end.flatten.uniq.each {|image| f.puts format_image(image).split("?").first }

      MagicBean::ItemBanner.all.pluck(:banner).uniq.compact.each {|image| f.puts format_image(image).split("?").first }

      MagicBean::Item.all.map do |item|
        ((item.main_images || []) + (item.detail_images || []) + [item.qrcode, item.cover, item.share_cover, item.detail_video, item.top_left_corner_tag_image]).compact
      end.flatten.uniq.each {|image| f.puts format_image(image).split("?").first }

      MagicBean::LiveRoom.all.map do |l|
        [l.bg_img, l.custom_page_icon, l.share_icon].compact
      end.flatten.uniq.each {|image| f.puts format_image(image).split("?").first }

      (MagicBean::OrderItem.select("image").distinct.pluck(:image) + MagicBean::StockKeepingUnit.select("image").distinct.pluck(:image)).compact.uniq.each {|image| f.puts format_image(image).split("?").first }

      MagicBean::OverseasStudentApplication.all.map do |o|
        [o.student_image_obverse_side, o.student_image_reverse_side].compact
      end.flatten.uniq.each {|image| f.puts format_image(image).split("?").first }

      MagicBean::PagePopup.all.pluck(:image).uniq.compact.each {|image| f.puts format_image(image).split("?").first }

      MagicBean::Page.all.pluck(:cover).uniq.compact.each {|image| f.puts format_image(image).split("?").first }

      MagicBean::Product.all.map do |product|
        ((product.main_images || []) + (product.detail_images || []) + [product.cover, product.share_cover, product.detail_video]).compact
      end.flatten.uniq.each {|image| f.puts format_image(image).split("?").first }
      
      MagicBean::PushMessage.all.pluck(:image).uniq.compact.each {|image| f.puts format_image(image).split("?").first }

      ActiveRecord::Base.connection.execute("SELECT image FROM qa_and_guarantee_translations").map {|row| row["image"]}.uniq.each {|image| f.puts format_image(image).split("?").first }

      MagicBean::QaAndGuarantee.all.pluck(:web_image).uniq.compact.each {|image| f.puts format_image(image).split("?").first }

      MagicBean::ShareSetting.all.map { |setting| [setting.share_background_cover, setting.share_cover, setting.search_cover].compact }.flatten.uniq.each {|image| f.puts format_image(image).split("?").first }
      
      MagicBean::SignInActivity.all.map { |ac| [ac.detail_image, ac.banner].compact }.flatten.uniq.each {|image| f.puts format_image(image).split("?").first }  
      
      # 现在site_configs的web_home_banners/web_item_list_images/web_welcome_image/web_item_list_video/web_event_list_video/web_welcome_video/customer_services的图片字段均为空，先不获取数据，等导出的时候再检查一遍
      MagicBean::SiteConfig.all.map do |setting|
        [setting.watermark_attributes&.dig("watermark_image_name"), setting.member_bg_image, setting.user_default_avatar, setting.cart_empty_image, setting.invitation&.dig("preview_image"), setting.base&.dig("all_category_icon"), setting.base&.dig("invite_page_banner")].compact
      end.flatten.uniq.each {|image| f.puts format_image(image).split("?").first }


      MagicBean::UserRecommendedProduct.all.pluck(:images).flatten.uniq.compact.each {|image| p format_image(image).split("?").first }
      MagicBean::UserSuggestion.all.pluck(:images).flatten.uniq.compact.each {|image| f.puts format_image(image).split("?").first }

      MagicBean::User.all.map { |user| [user.avatar, user.origin_avatar].compact }.flatten.uniq.each {|image| f.puts format_image(image).split("?").first }

      MagicBean::WebBannerItem.all.map { |item| [item.mobile_image_url, item.desktop_image_url].compact }.flatten.uniq.each {|image| f.puts format_image(image).split("?").first }

      MagicBean::WebCategory.all.map {|cate| [cate.icon, cate.filter_icon]}.flatten.uniq.compact.each {|image| f.puts format_image(image).split("?").first }

      MagicBean::WebItem.all.map do |item|
        ((item.upper_images || []) + (item.lower_images || []) + (item.banner_images || []) + [item.video]).compact
      end.flatten.uniq.each {|image| f.puts format_image(image).split("?").first }
    end

    puts "done"
  end

  desc "获取所有OSS文件url，并写入文件"
  task get_all_oss_data: :environment do
    file_path = Rails.root.join("tmp/oss_#{Time.current.to_i}.jsonl")

    limit = 200
    marker = nil
    File.open(file_path, "a") do |f|
      loop do
        objects = OSS.object_list(marker, limit)
      
        objects.each do |o|
          f.puts o.key
        end
  
        # 如果有下一页，更新 marker 继续获取
        break if objects.size < limit
        marker = objects.last.key
      end      
    end
  end

  # 1. 获取所有oms当前存在的链接
  # 2. 获取所有oss上的链接
  # 3. 如果oss链接不存在于oms，且不在page和CustomPage中，则删除
  desc "清理阿里云OSS上未使用的文件"
  task :clear_unused_oss_files, [:file_name] => :environment do |t, args|   
    oms_links = File.read(Rails.root.join("tmp/oms_oss_current.jsonl"))
    oss_links = File.read(Rails.root.join("tmp/#{args[:file_name]}.jsonl")).split("\n")
    oss_links.each do |link|
      next if oms_links.include?(link)
      # 额外比对字段：custom_pages: components, pages: content
      next if MagicBean::Page.ransack(content_cont: link).result.exists?
      next if MagicBean::CustomPage.where("CAST(components AS text) LIKE ?", "%#{link}%").exists?
      OSS.delete(link, false)
    end
  end

  # 将ebest-production.oss-ap-southeast-2.aliyuncs.com全部替换为cdn.minimall.donkibuy.com
  desc "更新旧的OSS链接"
  task update_old_oss_links: :environment do
    old_host = "http://ebest-production.oss-ap-southeast-2.aliyuncs.com"
    host = "https://cdn.minimall.donkibuy.com"

    # 以下model会持续出现包含旧域名的数据
    MagicBean::AfterSale.where("CAST(images AS text) LIKE ?", "%#{old_host}%").each do |after_sale|
      images = after_sale.images.map { |image| image.gsub(old_host, host) }
      after_sale.update_columns(images: images)
    end

    MagicBean::Comment.where("CAST(images AS text) LIKE ?", "%#{old_host}%").each do |comment|
      images = comment.images.map { |image| image.gsub(old_host, host) }
      comment.update_columns(images: images)
    end
    
    MagicBean::OverseasStudentApplication.ransack(student_image_obverse_side_cont: old_host).result.each do |application|
      application.update_columns(student_image_obverse_side: application.student_image_obverse_side.gsub(old_host, host))
    end

    MagicBean::UserRecommendedProduct.where("CAST(images AS text) LIKE ?", "%#{old_host}%").each do |product|
      images = product.images.map { |image| image.gsub(old_host, host) }
      product.update_columns(images: images)
    end

    MagicBean::UserSuggestion.where("CAST(images AS text) LIKE ?", "%#{old_host}%").find_each do |suggestion|
      images = suggestion.images.map { |image| image.gsub(old_host, host) }
      suggestion.update_columns(images: images)
    end

    MagicBean::User.ransack(origin_avatar_cont: old_host).result.find_each do |user|
      user.update_columns(origin_avatar: user.origin_avatar.gsub(old_host, host))
    end

    puts "done"
  end

  desc "更新产品相关图片为缩略水印图"
  task update_items_oss_links: :environment do
    host, thumbnail_prefix_path = AWS_CDN_HOST, AWS_THUMBNAIL_PREFIX_PATH

    # 产品、分类、品牌、SKU
    # 跳过QRccode
    MagicBean::Item.where(aws_lambda_image_generated: true).order(id: :asc).find_each do |item|
      main_images = item.main_images.present? ? item.main_images.map { |image| image.include?(thumbnail_prefix_path) ? image : image.gsub(host, thumbnail_prefix_path) } : item.main_images
      detail_images = item.detail_images.present? ? item.detail_images.map { |image| image.include?(thumbnail_prefix_path) ? image : image.gsub(host, thumbnail_prefix_path) } : item.detail_images
      cover, share_cover = item.cover, item.share_cover
      cover = cover.gsub(host, thumbnail_prefix_path) if cover.present? && cover.exclude?(thumbnail_prefix_path)
      share_cover = item.share_cover&.gsub(host, thumbnail_prefix_path) if share_cover.present? && share_cover.exclude?(thumbnail_prefix_path)
      
      # 存在差异再更新
      if main_images != item.main_images || detail_images != item.detail_images || cover != item.cover || share_cover != item.share_cover
        item.update_columns(main_images: main_images, detail_images: detail_images, cover: cover, share_cover: share_cover)
      end
    end

    MagicBean::Product.find_each do |product|
      main_images = product.main_images.present? ? product.main_images.map { |image| image.include?(thumbnail_prefix_path) ? image : image.gsub(host, thumbnail_prefix_path) } : product.main_images
      detail_images = product.detail_images.present? ? product.detail_images.map { |image| image.include?(thumbnail_prefix_path) ? image : image.gsub(host, thumbnail_prefix_path) } : product.detail_images
      
      cover, share_cover = product.cover, product.share_cover
      cover = product.cover&.gsub(host, thumbnail_prefix_path) if cover.present? && cover.exclude?(thumbnail_prefix_path)
      share_cover = product.share_cover&.gsub(host, thumbnail_prefix_path) if share_cover.present? && share_cover.exclude?(thumbnail_prefix_path)
      
      # 存在差异再更新
      if main_images != product.main_images || detail_images != product.detail_images || cover != product.cover || share_cover != product.share_cover
        product.update_columns(main_images: main_images, detail_images: detail_images, cover: cover, share_cover: share_cover)
      end
    end

    MagicBean::StockKeepingUnit.where(aws_lambda_image_generated: true).ransack(image_not_cont: thumbnail_prefix_path).result.find_each do |sku|
      sku.update_columns(image: sku.image.gsub(host, thumbnail_prefix_path))
    end

    MagicBean::OrderItem.ransack(image_not_cont: thumbnail_prefix_path).result.find_each do |order_item|
      next if order_item.image.include?("https://cdn.minimall.donkibuy.com/images/211015/i0viidjna.jpg") # 这个图片是旧的，生成缩略图会报错，所以用原图
      order_item.update_columns(image: order_item.image.gsub(host, thumbnail_prefix_path))
    end
    # 用这样更新更快
    # MagicBean::OrderItem.ransack(image_not_cont: thumbnail_prefix_path).result.update_all("image = REPLACE(image, 'cdn.minimall.donkibuy.com', 'cdn.minimall.donkibuy.com/750xAUTO')")

    MagicBean::Brand.where(aws_lambda_image_generated: true).ransack(cover_not_cont: thumbnail_prefix_path).result.find_each do |brand|
      brand.update_columns(cover: brand.cover.gsub(host, thumbnail_prefix_path))
    end

    MagicBean::Category.where(aws_lambda_image_generated: true).find_each do |category|
      icon, filter_icon = category.icon, category.filter_icon
      icon = category.icon&.gsub(host, thumbnail_prefix_path) if icon.present? && icon.exclude?(thumbnail_prefix_path)
      filter_icon = category.filter_icon&.gsub(host, thumbnail_prefix_path) if filter_icon.present? && filter_icon.exclude?(thumbnail_prefix_path)
  
      category.update_columns(icon: icon, filter_icon: filter_icon)
    end

    puts "done"
  end

  def format_image(image)
    image.gsub("https://ebest-production.oss-ap-southeast-2.aliyuncs.com/", "").gsub("http://ebest-production.oss-ap-southeast-2.aliyuncs.com/", "").gsub("https://cdn.minimall.donkibuy.com/", "")
  end

  # oms数据库还包含一些不需要比对链接, 需要再过滤掉一些数据
  def format_links
    original_path = Rails.root.join("tmp/oms_oss.jsonl")
    data = File.read(original_path)
    file_path = Rails.root.join("tmp/oms_oss_current.jsonl")

    File.open(file_path, "a") do |f|
      data.split("\n").uniq.compact.each do |link|
        next if link.include?("thirdwx.qlogo.cn")
        next if link.include?("wx.qlogo.cn")
        f.puts link
      end
    end

    FileUtils.rm original_path

    puts "done"
  end

  # OSS有几千万个文件，为了避免读取时占用太多内存，拆分成多个文件
  # 将大文件分成多个文件，每个文件存50万条数据
  def split_files(file_name)
    oss_links = File.read(Rails.root.join("tmp/#{file_name}"))
    oss_links.split("\n").uniq.each_slice(500000).each_with_index do |links, i|
      file_path = Rails.root.join("tmp/shopline/oss_#{i + 1}.jsonl")

      File.open(file_path, "a") do |f|
        links.each do |link|
          f.puts link
        end
      end
    end

    puts "done"
  end
end
