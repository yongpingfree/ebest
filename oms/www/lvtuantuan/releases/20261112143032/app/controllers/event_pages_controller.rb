# frozen_string_literal: true

class EventPagesController < ApplicationController
  include UsersHelper
  YEARLY_REPORT_2021_USER_COUNT = 89822
  VALID_TOP_CATEGORY_IDS = [1, 3, 5, 48, 51, 76, 77, 111, 124, 133, 151, 156, 185, 269, 296, 297, 331, 646, 678, 692]

  helper_method :current_user

  def show
    session[:user_id] = current_user.id if payload && current_user
    if params[:slug] == "yearly_reports"
      return unless current_user

      orders = MagicBean::Order.paid.where(created_at: "2021-01-01".to_date.beginning_of_day.."2021-12-31".to_date.end_of_day)
      orders_sum = orders.group(:user_id).sum(:actually_amount_in_cent)
      orders_sum_sort = orders_sum.sort_by { |_key, value| value }.reverse.to_h.keys
      current_user_index = orders_sum_sort.index(current_user.id)

      actually_amount_in_cent = orders_sum[current_user.id]
      @total_amount_in_yuan = ActiveSupport::NumberHelper.number_to_currency(actually_amount_in_cent.to_i / 100.0, format: "%n", delimiter: "")

      @advance_percentage = if current_user_index.nil?
                              0
                            else
                              # 根据不同的消费金额，增加不同的排名偏移量，以下数据为客户提供
                              offset = if actually_amount_in_cent > 1000000
                                         0
                                       elsif actually_amount_in_cent > 500000
                                         670
                                       elsif actually_amount_in_cent > 100000
                                         7560
                                       elsif actually_amount_in_cent > 50000
                                         27560
                                       else
                                         61920
                                       end

                              ((1 - (current_user_index + offset) / YEARLY_REPORT_2021_USER_COUNT.to_f) * 100).round(2)
                            end

      current_user_orders = orders.where(user_id: current_user.id)

      target_category_id = current_user_orders.includes(:items).map { |order| order.items.map(&:parent_category_id) }.flatten.each_with_object(Hash.new(0)) { |word,counts| counts[word] += 1 }.max_by{ |_,v| v }&.first
      @category_name = target_category_id.present? ? MagicBean::Category.find(target_category_id).name : ""
      @sign_days = ((Time.current - current_user.created_at) / 1.day.second).to_i
    elsif params[:slug] == "yearly_reports_2022"
      return unless current_user
      @user_active = current_user.created_at.to_date < "2022-12-15".to_date
      return unless @user_active
      yearly_reports_data("2022-01-01", "2022-12-15")
    else
      @dragon_balls_start_at = MagicBean::EventPage.dragon_balls_start_at
    end
  end

  private

  # 2022跟2021报告有点不同，先以2022的逻辑写一遍，后续再复用
  def yearly_reports_data(start_date, end_date)
    end_time = end_date.to_date.end_of_day
    @sign_days = (end_date.to_date - current_user.created_at.to_date).to_i
    orders = MagicBean::Order.paid.where(created_at: "#{start_date}".to_date.beginning_of_day..end_time)
    current_user_orders = orders.where(user_id: current_user.id)

    # 如果用户订单为空，就无需做后面的计算
    if current_user_orders.blank?
      @user_active = false
      return
    end

    # 计算总消费金额及排名
    @total_amount_in_yuan, @total_amount_advance_percentage = calculate_advance_percentage(orders)

    # 计算当前门店消费排名
    # 计算用户下单最多的门店
    target_store_id = current_user_orders.group(:store_id).sum(:total_payment_in_cent).sort_by { |_key, value| value }.reverse.to_h.keys&.first
    @user_store_name = target_store_id.present? ? MagicBean::Store.find(target_store_id).name : ""
    _, @current_store_total_amount_advance_percentage = calculate_advance_percentage(orders, target_store_id)

    # 计算总下单次数、下单总商品数、下单商品数排名
    @orders_count = current_user_orders.size
    @total_quantity = MagicBean::OrderItem.where(order_id: current_user_orders.select(:id)).sum(:quantity)
    total_quantity_hash = MagicBean::OrderItem.includes(:order).where(order_id: orders.select(:id)).group("orders.user_id").sum(:quantity)
    total_quantity_sort = total_quantity_hash.sort_by { |_key, value| value }.reverse.to_h.keys
    order_quantity_current_user_index = total_quantity_sort.index(current_user.id)
    @quantity_advance_percentage = if order_quantity_current_user_index.nil?
                                     0
                                   else
                                     percentage = ((1 - order_quantity_current_user_index / total_quantity_sort.count.to_f) * 100).floor(2)
                                     percentage.zero? ? 0.01 : percentage
                                   end

    # 计算购买最多的一级分类
    target_category_id = current_user_orders.includes(:items).map { |order| order.items.map(&:parent_category_id) }.flatten.each_with_object(Hash.new(0)) { |word, counts| counts[word] += 1 if word.in?(VALID_TOP_CATEGORY_IDS) }.max_by { |_, v| v }&.first
    @category_name = target_category_id.present? ? MagicBean::Category.find(target_category_id).name : ""
    @user_title = user_title(@category_name)

    # 计算购买数量最多的商品
    target_item_id = MagicBean::OrderItem.where(order_id: current_user_orders.select(:id)).group(:item_id).sum(:quantity).max_by { |_, v| v }&.first
    @item_name = target_item_id.present? ? MagicBean::Item.find(target_item_id).name : ""

    # 计算优惠订单数（使用金币、礼品卡也算）
    # original_payment_in_cent为使用优惠前的商品总价 + 原始运费，所以要计算 payment_in_cent + freight_in_cent < original_payment_in_cent 数
    @use_coupon_orders_count = current_user_orders.where("(payment_in_cent + freight_in_cent) < original_payment_in_cent").count

    # 计算最晚一次下单时间，最晚时间截止到第二日的6:00的时间，并显示xx:xx
    latest_order_time = nil
    current_user_orders.each do |order|
      if latest_order_time
        # 时间减6小时再做比对
        latest_time = (latest_order_time - 6.hours).strftime("%H:%M")
        order_time = (order.created_at - 6.hours).strftime("%H:%M")
        latest_order_time = order.created_at if order_time > latest_time
      else
        latest_order_time = order.created_at
      end
    end
    @latest_order_time_format = latest_order_time&.strftime("%H") # 只展示小时
  end

  def user_title(category_name)
    case category_name
    when "蔬菜水果"
      "蔬果达人"
    when "快手美食"
      "美食达人"
    when "优选零食", "各式饮品", "甜品烘焙"
      "味蕾收藏家"
    when "粮油副食"
      "烹饪爱好者"
    when "美妆个护", "个人洗护"
      "美妆达人"
    when "品质生活"
      "居家小能手"
    when "电子数码"
      "数码达人"
    when "教育中心"
      "学霸养成家"
    when "豆蛋奶类", "保健养生"
      "营养专家"
    when "宠物生活"
      "萌宠守护者"
    when "肉类精选"
      "肉肉爱好者"
    when "海鲜水产"
      "海味体验家"
    when "玩转澳洲"
      "美好发现者"
    when "母婴亲子"
      "萌娃养成家"
    when "eYoung"
      "潮流青年"
    when "爱车e族"
      "爱车达人"
    end
  end

  def calculate_advance_percentage(orders, store_id = nil)
    redis_key = "store-#{store_id}-orders-sum-sort"
    orders_sum_sort_json = Rails.cache.redis.get redis_key
    if orders_sum_sort_json
      orders_sum_sort = JSON.parse orders_sum_sort_json
    else
      # 应付金额
      orders = orders.where(store_id: store_id) if store_id
      orders_sum = orders.group(:user_id).sum(:total_payment_in_cent)
      orders_sum_sort = orders_sum.sort_by { |_key, value| value }.reverse.to_h

      # 从消费金额0.01-400，400.01-800….为一个区间，依次每个区间增加399.99。每个区间的增加的机器人数为该区间人数的6%，其中机器人的消费金额在该区间内随机生成
      orders_sum_sort_values = orders_sum_sort.values
      max_orders_sum = orders_sum_sort_values.first

      count = max_orders_sum / 40000
      count += 1 if (max_orders_sum % 40000) > 0
      last_min_value_index = orders_sum_sort_values.size - 1

      count.times do |n|
        max_payment_in_cent = 40000 * (n + 1)
        min_payment_in_cent = 0.01 + 40000 * n
        # 总金额超过18000不再增加假数据
        break if max_payment_in_cent > 1800000
        # 找到该区间最大值的下标，然后计算出该区间有多少人
        max_value_index = orders_sum_sort_values.index { |x| x <= max_payment_in_cent }
        users_count = last_min_value_index - max_value_index + 1
        # 0.01-400 + 50%, 往上每400 + 30%
        percent = 0.5 + 0.3 * n
        random_user_count = (users_count * percent).ceil
        random_user_count.times do |rn|
          orders_sum_sort["#{max_payment_in_cent}_#{rn}"] = rand(min_payment_in_cent..max_payment_in_cent).round
        end
        last_min_value_index = max_value_index - 1
      end

      # orders_sum_sort 加入机器人之后重新排序重新
      orders_sum_sort = orders_sum_sort.sort_by { |_key, value| value }.reverse.to_h
      Rails.cache.redis.set redis_key, orders_sum_sort.to_json
    end

    orders_sum_sort_values = orders_sum_sort.keys
    # 排名只按有下单的人来统计
    total_users_count = orders_sum_sort_values.size
    order_sum_current_user_index = orders_sum_sort_values.index(current_user.id) || orders_sum_sort_values.index("#{current_user.id}")

    total_payment_in_cent = orders_sum_sort[current_user.id] || orders_sum_sort["#{current_user.id}"]
    total_amount_in_yuan = ActiveSupport::NumberHelper.number_to_currency(total_payment_in_cent.to_i / 100.0, format: "%n", delimiter: "")

    total_amount_advance_percentage = if order_sum_current_user_index.nil? || total_payment_in_cent.zero?
                                        0
                                      else
                                        percentage = ((1 - order_sum_current_user_index / total_users_count.to_f) * 100).floor(2)
                                        percentage.zero? ? 0.01 : percentage
                                      end
    [total_amount_in_yuan, total_amount_advance_percentage]
  end
end
