# frozen_string_literal: true

module BeansAdmin::Helpers
  module AnalysisHelper
    def start_date
      @start_date ||= (params[:date_range]&.first || Date.current.prev_day(6))
    end

    def end_date
      @end_date ||= (params[:date_range]&.last || Date.current)
    end

    def analysis_time_range
      start_date.beginning_of_day..end_date.end_of_day
    end

    def completing_data(analyses_data)
      (start_date..end_date).map { |date| [date, analyses_data[date] || 0] }.to_h
    end

    def format_number(number)
      number.is_a?(Integer) ? number : ("%0.2f" % number)
    end

    # 由于pg用的中国时区，所以需要做两次转换
    def group_by_date_string
      "DATE(timezone('AEST', timezone('CCT', created_at)))"
    end

    # 计算每天的数据
    def page_view_data(_)
      Wechat::Api.get_weanalysis_appid_daily_visit_trend(start_date, end_date).compact.map { |o| [o["ref_date"].to_date, o["visit_pv"]] }.to_h
    end

    def user_view_data(_)
      Wechat::Api.get_weanalysis_appid_daily_visit_trend(start_date, end_date).compact.map { |o| [o["ref_date"].to_date, o["visit_uv"]] }.to_h
    end

    def shop_bag_item_count_data(_)
      @shop_bag_item_count_data ||= (start_date..end_date).map { |date| [date, Analyses::Cache.get("shop_bag_item_count", date)] }.to_h
    end

    def same_day_shop_bag_item_count_data(_)
      @same_day_shop_bag_item_count_data ||= (start_date..end_date).map { |date| [date, Analyses::Cache.get("same_day_shop_bag_item_count", date)] }.to_h
    end

    # 销售总额（订单实付金额）
    def orders_payment_sum_data(order_channel = nil)
      @orders_payment_sum_data ||= MagicBean::Order.where(created_at: analysis_time_range, channel: format_channel(order_channel)).paid.ransack({ store_id_eq: params[:store_id_eq] }).result.group(group_by_date_string).sum(:payment_in_cent).transform_values { |v| v / 100.0 }.to_h
    end

    # 销量总额（GMV，订单优惠前金额）
    def orders_gmv_sum_data(order_channel = nil)
      @orders_gmv_sum_data ||= MagicBean::Order.where(created_at: analysis_time_range, channel: format_channel(order_channel)).paid.ransack({ store_id_eq: params[:store_id_eq] }).result.group(group_by_date_string).sum(:amount_in_cent).transform_values { |v| v / 100.0 }.to_h
    end

    # 支付总额(未退货)
    def orders_actually_amount_sum_data(order_channel = nil)
      @orders_actually_amount_sum_data ||= MagicBean::Order.where(created_at: analysis_time_range, channel: format_channel(order_channel)).paid.ransack({ store_id_eq: params[:store_id_eq] }).result.group(group_by_date_string).sum(:actually_amount_in_cent).transform_values { |v| v / 100.0 }.to_h
    end

    # 用户发起的成功售后总额
    def user_finished_after_sales_amount_sum_data(_)
      @user_finished_after_sales_amount_sum_data ||= finished_after_sales_amount_sum_data("user")
    end

    # 系统发起的成功售后总额
    def wms_finished_after_sales_amount_sum_data(_)
      @wms_finished_after_sales_amount_sum_data ||= finished_after_sales_amount_sum_data("wms")
    end

    # 成功售后总额
    def finished_after_sales_amount_sum_data(applicant_type = nil)
      MagicBean::AfterSale.where(created_at: analysis_time_range).finished.ransack({ store_id_eq: params[:store_id_eq], applicant_type_eq: applicant_type }).result.group(group_by_date_string).sum(:amount_in_cent).transform_values { |v| v / 100.0 }.to_h
    end

    # 下单订单数
    def orders_count_data(order_channel = nil)
      @orders_count_data ||= MagicBean::Order.where(created_at: analysis_time_range, channel: format_channel(order_channel)).ransack({ store_id_eq: params[:store_id_eq] }).result.group(group_by_date_string).count.to_h
    end

    # 支付订单数
    def paid_orders_count_data(order_channel = nil)
      @paid_orders_count_data ||= MagicBean::Order.where(created_at: analysis_time_range, channel: format_channel(order_channel)).paid.ransack({ store_id_eq: params[:store_id_eq] }).result.group(group_by_date_string).count.to_h
    end

    # 支付订单数(未退货)
    def paid_and_without_all_refund_orders_count_data(order_channel = nil)
      @paid_and_without_all_refund_orders_count_data ||= MagicBean::Order.where(created_at: analysis_time_range, channel: format_channel(order_channel)).where.not(actually_amount_in_cent: 0).paid.ransack({ store_id_eq: params[:store_id_eq] }).result.group(group_by_date_string).count.to_h
    end

    # 下单买家数
    def orders_user_count_data(order_channel = nil)
      @orders_user_count_data ||= MagicBean::Order.where(created_at: analysis_time_range, channel: format_channel(order_channel)).ransack({ store_id_eq: params[:store_id_eq] }).result.group(group_by_date_string).count("DISTINCT user_id").to_h
    end

    # 支付买家数
    def paid_orders_user_count_data(order_channel = nil)
      @paid_orders_user_count_data ||= MagicBean::Order.where(created_at: analysis_time_range, channel: format_channel(order_channel)).paid.ransack({ store_id_eq: params[:store_id_eq] }).result.group(group_by_date_string).count("DISTINCT user_id").to_h
    end

    # 支付买家数(未退货)
    def paid_and_without_all_refund_orders_user_count_data(order_channel = nil)
      @paid_and_without_all_refund_orders_user_count_data ||= MagicBean::Order.where(created_at: analysis_time_range, channel: format_channel(order_channel)).where.not(actually_amount_in_cent: 0).paid.ransack({ store_id_eq: params[:store_id_eq] }).result.group(group_by_date_string).count("DISTINCT user_id").to_h
    end

    # 自派订单地址数
    def merchant_delivery_addresses_count_data(order_channel = nil)
      @merchant_delivery_addresses_count_data ||= MagicBean::Order.merchant_delivery.where('DATE("delivery_date") BETWEEN ? AND ?', start_date, end_date).where(status: MagicBean::Order::PAID_STATUS, channel: format_channel(order_channel)).ransack({ store_id_eq: params[:store_id_eq] }).result.group('DATE("delivery_date")').count("DISTINCT receiver_properties").to_h
    end

    # 自派订单额外上限地址数
    def extra_merchant_delivery_addresses_count_data(order_channel = nil)
      @extra_merchant_delivery_addresses_count_data ||= MagicBean::Order.merchant_delivery.where('DATE("delivery_date") BETWEEN ? AND ?', start_date, end_date).where(next_day_delivery: true, mark_for_orders_limit: true, status: MagicBean::Order::PAID_STATUS, channel: format_channel(order_channel)).ransack({ store_id_eq: params[:store_id_eq] }).result.group('DATE("delivery_date")').count("DISTINCT receiver_properties").to_h
    end

    # 浏览-下单转化率(只统计小程序订单)
    def order_rate_data(order_channel = nil)
      user_view_data(order_channel).to_h.map { |k, v| [k, v == 0 ? 0 : (orders_user_count_data("mini_program")[k.to_date].to_i / v.to_f * 100).round(2)] }.to_h
    end

    # 客单价 = 销售金额 / 支付订单数
    def per_customer_transaction_data(order_channel = nil)
      orders_payment_sum_data(order_channel).map do |k, v|
        [k, (v / paid_orders_count_data[k]).round(2)]
      end.to_h
    end

    # 客单件 = 支付总件数 / 支付订单数
    def per_customer_products_data(order_channel = nil)
      items_count = MagicBean::OrderItem.where(order_id: MagicBean::Order.where(created_at: analysis_time_range, channel: format_channel(order_channel)).paid.ids).ransack({ store_id_eq: params[:store_id_eq] }).result.group(group_by_date_string).sum(:quantity)
      items_count.map { |k, v| [k, (v / paid_orders_count_data[k].to_f).round(0)] }.to_h
    end

    # 计算时间段内的数据
    def shop_bag_item_count_period_data(order_channel = nil)
      shop_bag_item_count_data(order_channel).values.map(&:to_i).sum
    end

    def same_day_shop_bag_item_count_period_data(order_channel = nil)
      same_day_shop_bag_item_count_data(order_channel).values.map(&:to_i).sum
    end

    def orders_payment_sum_period_data(order_channel = nil)
      orders_payment_sum_data(order_channel).values.sum
    end

    def orders_gmv_sum_period_data(order_channel = nil)
      orders_gmv_sum_data(order_channel).values.sum
    end

    def orders_actually_amount_sum_period_data(order_channel = nil)
      orders_actually_amount_sum_data(order_channel).values.sum
    end

    def finished_after_sales_amount_sum_period_data(_)
      finished_after_sales_amount_sum_data(nil).values.sum
    end

    def user_finished_after_sales_amount_sum_period_data(_)
      user_finished_after_sales_amount_sum_data(nil).values.sum
    end

    def wms_finished_after_sales_amount_sum_period_data(_)
      wms_finished_after_sales_amount_sum_data(nil).values.sum
    end

    def orders_count_period_data(order_channel = nil)
      orders_count_data(order_channel).values.sum
    end

    def paid_orders_count_period_data(order_channel = nil)
      paid_orders_count_data(order_channel).values.sum
    end

    def paid_and_without_all_refund_orders_count_period_data(order_channel = nil)
      paid_and_without_all_refund_orders_count_data(order_channel).values.sum
    end

    def merchant_delivery_addresses_count_period_data(order_channel = nil)
      merchant_delivery_addresses_count_data(order_channel).values.sum
    end

    def extra_merchant_delivery_addresses_count_period_data(order_channel = nil)
      extra_merchant_delivery_addresses_count_data(order_channel).values.sum
    end

    def orders_user_count_period_data(order_channel = nil)
      @orders_user_count_period_data ||= MagicBean::Order.where(created_at: analysis_time_range, channel: format_channel(order_channel)).ransack({ store_id_eq: params[:store_id_eq] }).result.count("DISTINCT user_id")
    end

    def paid_orders_user_count_period_data(order_channel = nil)
      @paid_orders_user_count_period_data ||= MagicBean::Order.where(created_at: analysis_time_range, channel: format_channel(order_channel)).paid.ransack({ store_id_eq: params[:store_id_eq] }).result.count("DISTINCT user_id")
    end

    def paid_and_without_all_refund_orders_user_count_period_data(order_channel = nil)
      @paid_and_without_all_refund_orders_user_count_period_data ||= MagicBean::Order.where(created_at: analysis_time_range, channel: format_channel(order_channel)).where.not(actually_amount_in_cent: 0).paid.ransack({ store_id_eq: params[:store_id_eq] }).result.count("DISTINCT user_id")
    end

    # 客单价 = 支付金额 / 支付订单数
    def per_customer_transaction_period_data(order_channel = nil)
      paid_orders_count_period_data(order_channel) > 0 ? (orders_payment_sum_period_data(order_channel) / paid_orders_count_period_data(order_channel).to_f).round(2) : 0
    end

    # 客单件 = 支付总件数 / 支付订单数
    def per_customer_products_period_data(order_channel = nil)
      items_count = MagicBean::OrderItem.where(order_id: MagicBean::Order.where(created_at: analysis_time_range, channel: format_channel(order_channel)).paid.ids).ransack({ store_id_eq: params[:store_id_eq] }).result.sum(:quantity)
      paid_orders_count_period_data > 0 ? (items_count / paid_orders_count_period_data.to_f).round(0) : 0
    end

    def format_channel(order_channel = nil)
      (order_channel.blank? || order_channel == "all") ? MagicBean::Order.channels.keys : order_channel
    end
  end
end
