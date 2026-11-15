# frozen_string_literal: true
module MagicBean
  class SameDayDeliveryOrder < Order
    # scope

    # constants
    SAME_DAY_DELIVERY_CUTOFF_TIME = "14:00" # 当日达截单时间点 14时
    SAME_DAY_DELIVERY_DISPLAY_START_AT = "22:00" # 当日达截单开始展示时间点 22时
    SAME_DAY_PERIOD_MERCHANT_ADDRESSES_KEY = "delivery-time-%{delivery_time_id}-%{delivery_date}-period-%{period_id}-same-day-addresses"
    SAME_DAY_PERIOD_MERCHANT_ADDRESSES_COUNT_KET = "delivery-time-%{delivery_time_id}-%{delivery_date}-period-%{period_id}-same-day-addresses-count"

    # attr related macros

    # association macros
    belongs_to :same_day_delivery_time_period, optional: true

    # validation macros
    validate :check_delivery_type, on: :create

    # callbacks

    # other macros

    def order_name
      "当日达订单"
    end

    # 未发货的相同地址相同配送方式的母单或子单
    # TODO: Denis说现在当日达只有设置一个配送时间段，所以是否可加单先不考虑时间段，只考虑日期
    def user_child_or_parent_orders_without_date_condition(child = false)
      # 只拿当日达订单
      user.orders.where.not(id: id).where(type: "MagicBean::SameDayDeliveryOrder", status: [:risk_pay, :wait_seller_send_goods], delivery_type: delivery_type, is_child: child, live_top: false)
        .where("lower(receiver_properties -> 'province_name') like :lower_province_name and lower(receiver_properties -> 'city_name') like :lower_city_name and receiver_properties -> 'postal_code' like :postal_code and lower(receiver_properties -> 'street') like :lower_street and lower(receiver_properties -> 'street_number') like :lower_street_number",
               lower_province_name: "%#{receiver_province_name&.downcase}%", lower_city_name: "%#{receiver_city_name&.downcase}%", postal_code: "%#{receiver_postal_code}%", lower_street: "%#{receiver_street&.downcase}%", lower_street_number: "%#{receiver_street_number&.downcase}%")
    end

    def calculate_freight

      return self.freight_in_cent = 0 if delivery_type.blank?

      # 计算不同商品的运费最大值，使用其作为总运费
      total_weight_in_gram = order_items.sum { |item| item.weight_in_gram * item.quantity }
      
       # 每个门店同个配送方式最多会有两个运费模板（AE运费模板和普通运费模板各一个）
      # 需要根据ae_drop_shipper判断使用哪个模板
      default_freight_template = default_freight_templates.where(ae_drop_shipper: ae_drop_shipper).public_send(delivery_type).first
      # 适配的特殊地区模板
      exceptional_freight_template = default_freight_template&.exceptional_freight_templates
        &.ransack(
          au_suburbs_postal_code_eq: receiver_postal_code,
          au_suburbs_name_case_insensitive_eq: receiver_city_name&.downcase
        )&.result&.first
      
      # 计算设置了运费模板商品的运费
      template_items_freights = default_freight_template&.calculate_freight(total_weight_in_gram, receiver_postal_code, receiver_city_name, exceptional_freight_template)
      
      self.freight_in_cent, self.freight_cost_in_cent  = order_items.map(&:item).uniq.map do |item|
        if delivery_type.in? item.delivery_type
          if item.freight_fixed?
            [item.fixed_freight, item.fixed_freight_cost]
          elsif item.freight_template?
            template_items_freights || [0, 0]
          else
            [0, 0]
          end
        else
          [0, 0]
        end        
      end.max

      # 默认模板中的免邮金额(分)
      default_free = default_freight_template&.send("#{channel}_free_shipping_amount_in_cent")

      # 特殊模板中的免邮金额(分)
      exceptional_free = exceptional_freight_template&.send("#{channel}_free_shipping_amount_in_cent")

      # 运费固定商品金额
      freight_fixed_order_item_amount_in_cent = 0
      # 不参与包邮计算的金额
      not_free_shipping_amount_in_cent = 0
      order_items.each do |oi|
        item = oi.item

        if item.freight_fixed?
          freight_fixed_order_item_amount_in_cent += oi.amount_in_cent
          next
        end

        unless item.free_shipping
          oi.calculate_real_price
          not_free_shipping_amount_in_cent += oi.real_amount_in_cent
        end
      end

      # 参与包邮计算的费用
      free_shipping_amount_in_cent = total_payment_in_cent - freight_fixed_order_item_amount_in_cent - not_free_shipping_amount_in_cent

      # 如果设置了偏远地区，但没有设置免邮运费，运费不能为0
      if exceptional_freight_template.present?
        self.freight_in_cent = 0 if exceptional_free.present? && free_shipping_amount_in_cent >= exceptional_free
      elsif default_free.present?
        self.freight_in_cent = 0 if free_shipping_amount_in_cent >= default_free
      end

      # 当日达自派订单计算额外运费：订单总金额 - 不参与包邮金额
      same_day_free_shipping_amount_in_cent = total_payment_in_cent - not_free_shipping_amount_in_cent

      # 如果选择了时间窗口，需要增加额外运费
      if merchant_delivery? && same_day_delivery_time_period.present? && same_day_delivery_time_period.extra_shipping_amount_in_cent.to_i.positive? && same_day_free_shipping_amount_in_cent < same_day_delivery_time_period.free_shipping_amount_in_cent.to_i
        self.freight_in_cent += same_day_delivery_time_period.extra_shipping_amount_in_cent
      end

      # 当日达也要支持加单
      if freight_in_cent.positive? && has_other_parent_orders?
        self.freight_in_cent = 0
        self.is_child = true
      end
    end

    def enqueue_set_order_confirmed_job
      cutoff_time_setting = current_store_site_config.same_day_delivery_cutoff_time || {}

      time_at_string = cutoff_time_setting["time"] || SAME_DAY_DELIVERY_CUTOFF_TIME

      # 当日达订单只有自派自提，当日达订单当天确认
      cutoff_time = "#{delivery_date} #{time_at_string}".in_time_zone(order_store_time_zone)
      confirm_time = cutoff_time + CONFIRM_ORDER_TIME_AFTER_CUTOFF_TIME

      SetOrderConfirmedJob.set(wait_until: confirm_time).perform_later(id, true, cutoff_time.to_date.to_s) if final_amount_in_yuan_num < 1000
    end

    def available_delivery_time
      return unless merchant_delivery? || self_pick?

      if merchant_delivery?
        @available_delivery_time ||= current_delivery_area&.same_day_delivery_time
      else
        @available_delivery_time ||= self_pick_up
      end
    end

    def calculate_earliest_delivery_date
      return [@earliest_delivery_date, @conflicted_items] if @earliest_delivery_date.present?
      current_time = Time.current

      delivery_dates, conflicted_items = [], []
      # 可能会出现个别商品无配送日期
      order_items.map(&:item).map do |item|
        d_date = if merchant_delivery?
                   item.calculate_same_day_delivery_date(current_time, user_postal_code, user_suburb)
                 elsif self_pick?
                   item.calculate_same_day_delivery_date(current_time, nil, nil, self_pick_up_id)
                 end
        if d_date.blank?
          conflicted_items << item.title
        else
          delivery_dates << d_date
        end
      end

      if delivery_dates.blank?
        @earliest_delivery_date, @conflicted_items = nil, []
      else
        @earliest_delivery_date = delivery_dates.uniq.first
        @conflicted_items = conflicted_items
        [@earliest_delivery_date, @conflicted_items]
      end
    end

    def available_delivery_dates
      return @available_delivery_dates if @available_delivery_dates.present?
      return [] if available_delivery_time.nil?
      available_date, conflicted_items = calculate_earliest_delivery_date

      return [] if available_date.blank?
      # 如果有商品没有计算出配送日期，则提示
      if conflicted_items.present? && order_items.size > 1
        errors.add(:base, I18n.t("error.order.same_day_conflicted_items", item_titles: conflicted_items.join("; ")))
        return []
      end

      return [] unless available_date.wday.to_s.in?(available_delivery_time.weekdays)

      @available_delivery_dates = []

      if merchant_delivery?
        # 受限于全站地址数
        # 1. 全站地址数不限，则要单独比对每个时间段的地址数
        # 2. 全站地址数有限，先比对订单总地址数，再比对每个时间段地址数
        # 不受限于全站地址数，则直接比对每个时间段地址数
        available_periods = []

        if available_delivery_time.limited_by_orders_limit_every_day && merchant_delivery_address_limit.positive?
          distinct_address_count = merchant_distinct_address_count(available_date)
          return [] if merchant_delivery_address_limit <= distinct_address_count
        end

        available_delivery_time.same_day_delivery_time_periods.each do |period|
          address_count_limit = period.address_count_limit.to_i
          same_day_period_distinct_address_count = same_day_period_merchant_distinct_address_count(available_date, period.id)

          if address_count_limit.zero? || same_day_period_distinct_address_count < period.address_count_limit
            available_periods << { id: period.id, time_period: period.time_period, time_window: period.time_window }
          end
        end

        @available_delivery_dates << { date: available_date, wday: I18n.l(available_date, format: "%a"), time_periods: available_periods }
      elsif self_pick?
        orders_count = self_pick_date_orders_count(available_date)
        if self_pick_orders_limit.zero? || self_pick_orders_limit > orders_count
          time_periods = self_pick_up.time_period.map { |period| { id: nil, time_period: period } }
          @available_delivery_dates << { date: available_date, wday: I18n.l(available_date, format: "%a"), time_periods: time_periods }
        end
      end

      @available_delivery_dates
    end

    private

    def generate_order_no
      no_prefix = Rails.env.production? ? "" : "S"
      loop do
        self.no = no_prefix + Time.now.strftime("%Y%m%d%H%M%L") + rand.to_s[2..4]
        break unless MagicBean::Order.exists?(no: no)
      end
    end

    def check_delivery_type
      errors.add(:base, I18n.t("error.order.delivery_type_not_correct")) unless delivery_type.in?(["merchant_delivery", "self_pick"])
    end

    def check_delivery_time
      if !is_preview
        errors.add(:base, I18n.t("error.order.delivery_time_presence")) if delivery_date.blank? || prefer_time.blank?
        if merchant_delivery?
          if same_day_delivery_time_period.blank?
            errors.add(:base, I18n.t("error.order.same_day_time_period_not_exist"))
          elsif !available_delivery_time.same_day_delivery_time_periods.exists?(id: same_day_delivery_time_period_id, time_period: prefer_time)
            errors.add(:base, I18n.t("error.order.same_day_time_period_not_match"))
          end
        end
      end

      return if available_delivery_time.nil?
      if delivery_date.blank? && prefer_time.blank? && (merchant_delivery? || (self_pick? && self_pick_up.present?))
        # 由于商家配送时间段有额外运费，所以不默认选择
        if self_pick?
          self.prefer_time = available_delivery_time.time_period.first
        # elsif merchant_delivery?
        #   # TODO: 由于app也做了限制不默认选择配送时间，所以暂时不需要默认选择
        #   default_time_period = available_delivery_time.same_day_delivery_time_periods.first
        #   self.prefer_time = default_time_period&.time_period
        #   self.same_day_delivery_time_period_id = default_time_period&.id
        end

        self.delivery_date = available_delivery_dates.first[:date] if available_delivery_dates.present?
      end

      if merchant_delivery?
        self.mark_for_orders_limit = available_delivery_time.limited_by_orders_limit_every_day
        self.same_day_delivery_time_id = available_delivery_time&.id
      end

      if !is_preview && !delivery_date.to_date.wday.to_s.in?(available_delivery_time.weekdays)
        if merchant_delivery?
          errors.add(:base, I18n.t("error.order.time_not_support_merchant_delivery")) unless available_delivery_time.same_day_delivery_time_periods.exists?(id: same_day_delivery_time_period_id, time_period: prefer_time)
        else
          errors.add(:base, I18n.t("error.order.time_not_support_self_pickup")) unless prefer_time.in?(available_delivery_time.time_period)
        end
      end
    end

    def remove_shopping_cart_items
      return if is_direct_buy
      user.same_day_delivery_cart_items
        .where(
          stock_keeping_unit_id: order_items.map(&:stock_keeping_unit_id)
        ).destroy_all
    end

    def same_day_period_merchant_addresses_redis_key(new_delivery_date = nil)
      SAME_DAY_PERIOD_MERCHANT_ADDRESSES_KEY % { delivery_time_id: same_day_delivery_time_id, period_id: same_day_delivery_time_period_id, delivery_date: new_delivery_date || delivery_date }
    end

    def same_day_period_merchant_addresses_count_redis_key(new_delivery_date = nil, period_id = nil)
      SAME_DAY_PERIOD_MERCHANT_ADDRESSES_COUNT_KET % { delivery_time_id: same_day_delivery_time_id || available_delivery_time&.id, period_id: period_id || same_day_delivery_time_period_id, delivery_date: new_delivery_date || delivery_date }
    end

    def same_day_period_merchant_distinct_address_count(delivery_date, period_id = nil)
      Rails.cache.redis.get(same_day_period_merchant_addresses_count_redis_key(delivery_date, period_id)).to_i
    end

    def set_default_delivery_type
      return if !self.new_record? || !is_preview || delivery_type
      self.delivery_type = (["merchant_delivery", "self_pick"] & items_available_delivery_types).first
    end

    def counter_to_redis
      return if delivery_date.blank?

      if self_pick?
        Rails.cache.redis.incrby self_pick_order_limit_redis_key, 1
      elsif merchant_delivery? && receiver_properties.present?
        address_key = "#{receiver_properties.to_json}_same_day"

        if available_delivery_time&.limited_by_orders_limit_every_day
          # 当日达订单地址也要计算的原来的订单地址里面，但当日达订单跟普通订单地址数要区分开, 所以加same_day后缀
          redis_key = merchant_order_limit_redis_key
          Rails.cache.redis.hincrby(redis_key, address_key, 1)
          recalculate_merchant_orders_data
        end

        # 不需要记录delivery_time地址数，只需要记录到时间段
        Rails.cache.redis.hincrby same_day_period_merchant_addresses_redis_key, address_key, 1
        recalculate_delivery_time_orders_data
      end
    end

    def release_counter_from_redis
      return if delivery_date.blank?

      if self_pick?
        # 自减自提订单上限统计
        self_pick_count = Rails.cache.redis.incrby self_pick_order_limit_redis_key, -1
        Rails.cache.redis.del self_pick_order_limit_redis_key unless self_pick_count.positive?
      elsif merchant_delivery? && receiver_properties.present?
        address_key = "#{receiver_properties.to_json}_same_day"

        if available_delivery_time&.limited_by_orders_limit_every_day
          # 自减自派订单上限统计
          redis_key = merchant_order_limit_redis_key
          count = Rails.cache.redis.hincrby redis_key, address_key, -1
          Rails.cache.redis.hdel redis_key, address_key unless count.positive?
          recalculate_merchant_orders_data
        end

        # 自减区域特定订单上限统计
        delivery_time_count = Rails.cache.redis.hincrby same_day_period_merchant_addresses_redis_key, address_key, -1
        Rails.cache.redis.hdel delivery_time_order_limit_redis_key, address_key unless delivery_time_count.positive?
        recalculate_delivery_time_orders_data
      end
    end

    def set_order_date_analysis_to_redis(new_delivery_date, add_count = 1)
      if merchant_delivery?
        address_key = "#{receiver_properties.to_json}_same_day"

        if mark_for_orders_limit
          redis_key = merchant_order_limit_redis_key(new_delivery_date)
          count = Rails.cache.redis.hincrby redis_key, address_key, add_count
          Rails.cache.redis.hdel redis_key, address_key unless count.positive?
          recalculate_merchant_orders_data(new_delivery_date)
        end

        delivery_time_count = Rails.cache.redis.hincrby same_day_period_merchant_addresses_redis_key(new_delivery_date), address_key, add_count
        Rails.cache.redis.hdel same_day_period_merchant_addresses_redis_key(new_delivery_date), address_key unless delivery_time_count.positive?
        recalculate_delivery_time_orders_data(new_delivery_date)
      elsif self_pick?
        self_pick_count = Rails.cache.redis.incrby self_pick_order_limit_redis_key(new_delivery_date), add_count
        Rails.cache.redis.del self_pick_order_limit_redis_key(new_delivery_date) unless self_pick_count.positive?
      end
    end

    # 复写，只需要记录时间段地址数
    def recalculate_delivery_time_orders_data(new_delivery_date = nil)
      period_order_limit = Rails.cache.redis.hgetall(same_day_period_merchant_addresses_redis_key(new_delivery_date))
      addresses_count = period_order_limit.keys.count
      Rails.cache.redis.set same_day_period_merchant_addresses_count_redis_key(new_delivery_date), addresses_count
    end
  end
end
