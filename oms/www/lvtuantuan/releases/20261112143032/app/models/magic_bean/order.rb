# frozen_string_literal: true
module MagicBean
  class Order < ApplicationRecord
    include AASM
    include AASMExtendConcern
    include PaymentConcern
    include PriceConvertConcern
    include RefundIntegralConcern
    include OrderWechatTemplateDataConcern
    include PeriodScopeConcern
    include Order::Messages, Order::Integral, Order::CommwebPayment, Order::Omipay, Order::SelfPick, Order::Supay, Order::KlaviyoEmail, Order::Stripe, Order::SendgridEmail
    include OrderConcern::GiftActivity
    include OrderConcern::PreferentialPool

    # 快马配送的区域邮编
    KUAIMA_DELIVERY_POST_CODES = %w[2017 2018 2020 2023 2024 2027 2028 2029 2035 2037 2038 2039 2040 2041 2042 2043 2045 2046 2047 2048 2049 2050 2061 2062 2063 2064 2066 2068 2069 2070 2071 2072 2073 2074 2075 2076 2077 2079 2085 2086 2087 2088 2090 2092 2093 2094 2095 2096 2097 2099 2100 2101 2102 2103 2104 2106 2107 2110 2111 2114 2115 2116 2117 2118 2119 2120 2122 2125 2126 2127 2128 2130 2131 2132 2133 2134 2135 2136 2137 2138 2140 2141 2142 2143 2144 2145 2146 2147 2148 2150 2151 2152 2153 2154 2155 2156 2160 2161 2162 2163 2164 2165 2166 2167 2168 2170 2171 2172 2174 2175 2176 2177 2178 2179 2190 2191 2192 2193 2194 2195 2196 2197 2198 2199 2200 2203 2204 2205 2206 2207 2208 2209 2210 2211 2212 2213 2214 2216 2217 2218 2219 2220 2221 2222 2223 2224 2225 2226 2227 2228 2229 2232 2233 2234 2557 2558 2559 2564 2565 2566 2567 2747 2748 2749 2750 2759 2760 2761 2762 2763 2766 2767 2768 2769 2770 2773 2774 2776 2777]
    KUAIMA_COMPANY = "KUAIMA".freeze

    @@special_logger = ::Logger.new("./log/special_order_error.log")

    # scope
    scope :earning, -> { where(arel_table[:actually_amount_in_cent].gteq(0)) }
    scope :paid, -> { where(status: MagicBean::Order::PAID_STATUS) }
    scope :last_month_finished, -> { trade_finished.where("finished_at BETWEEN ? AND ?", 1.month.ago.beginning_of_month - FINISH_ORDER_TIME, 1.month.ago.end_of_month - FINISH_ORDER_TIME) }
    scope :current_month_finished, -> { trade_finished.where("finished_at BETWEEN ? AND ?", Time.current.beginning_of_month - FINISH_ORDER_TIME, Time.current.end_of_month - FINISH_ORDER_TIME) }
    scope :history_finished, -> { trade_finished.where("finished_at < ?", Time.current) }
    # effective 订单记录已经占有货物
    scope :effective, -> { where(status: %i[wait_buyer_pay wait_seller_send_goods wait_buyer_confirm_goods trade_finished buyer_confirm_goods apply_refund risk_pay live_top_confirm]) }
    # valid 无售后记录
    scope :valid, -> { select { |order| order.after_sales.empty? } }
    scope :trade_not_close, -> { where.not(status: :trade_closed) }
    scope :visible, -> { where(deleted_by_user_at: nil) }

    def self.ransackable_scopes(auth_object = nil)
      ["paid"]
    end

    # constants
    CUTOFF_TIME = "22:00" # 截单时间点 22时
    CONFIRM_ORDER_TIME_AFTER_CUTOFF_TIME = 17.minutes
    ClOSE_ORDER_TIME = 15.minutes
    CONFIRM_GOODS_TIME = 7.days
    AE_CONFIRM_GOODS_TIME = 30.days
    AE_SYNC_ORDER_STATUS_INTERVAL = 1.hour
    FINISH_ORDER_TIME = 7.days
    MAX_DELIVERY_DAY = 7
    AFTER_SALES_CREATABLE_STATUSES = %w[wait_buyer_confirm_goods buyer_confirm_goods]
    AFTER_SALES_CREATABLE_TYPES = %w[MagicBean::NormalOrder MagicBean::GrouponOrder MagicBean::VirtualOrder]
    PAID_STATUS = %i[wait_seller_send_goods wait_buyer_confirm_goods trade_finished buyer_confirm_goods apply_refund risk_pay live_top_confirm]
    RECEIVER_PROPERTIES = %w[id email city_name tel_number pure_detail_info detail_info postal_code company_name province_name street_number street first_name last_name unit_number]
    DIRECT_REFUND_WECHAT_KEY = "final_amount_in_cent - CEILING(payment_in_cent * wechat_service_percentage / 100.0)"
    DIRECT_REFUND_CREDIT_CARD_KEY = "final_amount_in_cent - CEILING(payment_in_cent * credit_card_service_percentage / 100.0)"
    DIRECT_REFUND_OMIPAY_KEY = "final_amount_in_cent - omipay_service_amount_dollar_in_cent"
    DIRECT_REFUND_SUPAY_KEY = "final_amount_in_cent - supay_service_amount_dollar_in_cent"
    MERCHANT_ORDER_LIMIT_REDIS_KEY = "store-%{store_id}-%{delivery_date}"
    DELIVERY_TIME_ORDER_LIMIT_REDIS_KEY = "delivery-time-%{delivery_time_id}-%{delivery_date}-list-period-%{period_id}"
    SELF_PICK_ORDER_LIMIT_REDIS_KEY = "self-pick-%{self_pick_up_id}-%{delivery_date}"
    FREE_SHIPPING_CODE = "FREESHIPPING"
    CHANNEL_PERMISSION_MAPPING = { # 使用字符串作为 key 和 value 方便对比，不然需要额外 to_s
      "app_channel_orders" => "app",
      "web_channel_orders" => "web",
      "mini_program_channel_orders" => "mini_program"
    }

    # 统计地址数存到redis
    MERCHANT_ADDRESSES_COUNT = "store-%{store_id}-%{delivery_date}-addresses-count"
    DELIVERY_TIME_ADDRESSES_COUNT = "delivery-time-%{delivery_time_id}-%{delivery_date}-addresses-count"
    DELIVERY_TIME_ADDRESSES_COUNT_WITH_PERIOD = "delivery-time-%{delivery_time_id}-%{delivery_date}-period-%{period_id}-addresses-count"

    MAX_SKU_QUANTITY_PER_ORDER = 600
    MAX_WAIT_BUYER_PAY_COUNT = 5

    SUPAY_WECHAT_KEY = "wechat"
    SUPAY_ALIPAT_KEY = "alipay"
    
    MAX_ORDER_WEIGHT = 20000 # 单位：克

    # attr related macros
    attr_accessor :ip_address, :is_direct_buy, :is_preview, :current_postal_code, :current_suburb, :free_shipping_code

    # payment_in_cent: 实付金额(不包含手续费))
    # payment_without_gift_card_in_cent: 实付金额(未减去礼品卡, 不包含手续费)
    # total_payment_in_cent: 优惠后的金额，包含积分（应付金额）
    # deliver_to_door_service_fee_in_cent: 送货上楼服务费
    # box_regulation_fee_in_cent: 超规费
    # package_service_fee_in_cent: 包装服务费
    # package_service_discount_in_cent: 包装服务费优惠
    # original_package_service_fee_in_cent: 原始包装服务费
    # amount_in_cent: 未计算优惠之前的原价格，amount_in_cent + freight_in_cent + deliver_to_door_service_fee_in_cent + box_regulation_fee_in_cent + package_service_fee_in_cent = original_payment_in_cent
    # actually_amount_in_cent: 减去售后之后的金额
    # cost_integral: 使用积分数
    # final_amount_in_cent: 最终支付金额，包含手续费
    # original_freight_in_cent: 基础运费
    # time_period_fee_in_cent: 指定时间段运费
    # long_distance_fee_in_cent: 远程运费
    # freight_in_cent: 最终支付运费（基础运费 + 指定时间段运费 + 远程运费 - 运费券）
    # freight_cost_in_cent: 运费成本
    # final_amount_without_gift_card_in_cent: 最终支付金额(未减去礼品卡，包含手续费)
    # final_amount_with_gift_card_in_cent: 最终支付金额(减去礼品卡，包含手续费)，跟final_amount_in_cent的区别是：final_amount_in_cent在没支付的时候值为空
    convert_price_to_yuan :payment_in_cent, :amount_in_cent, :freight_in_cent, :actually_amount_in_cent, :total_payment_in_cent, :invoicable_amount_in_cent,
      :original_payment_in_cent, :cost_integral_amount_in_cent, :wechat_payment_in_cent, :wechat_service_amount_in_cent, :credit_card_service_amount_in_cent,
      :credit_card_payment_in_cent, :wechat_payment_dollar_in_cent, :discount_amount_in_cent, :total_discount_amount_in_cent, :pool_discount_amount_in_cent,
      :vm_credit_card_payment_in_cent, :unionpay_credit_card_payment_in_cent, :final_amount_in_cent,
      :omipay_wechat_payment_dollar_in_cent, :omipay_wechat_payment_in_cent,
      :omipay_alipay_payment_dollar_in_cent, :omipay_alipay_payment_in_cent,
      :omipay_payment_dollar_in_cent, :omipay_payment_in_cent, :apple_pay_payment_in_cent, :cba_apple_pay_payment_in_cent, :cba_google_pay_payment_in_cent,
      :omipay_service_amount_dollar_in_cent, :omipay_service_amount_in_cent,
      :supay_wechat_payment_dollar_in_cent, :supay_wechat_payment_in_cent,
      :supay_alipay_payment_dollar_in_cent, :supay_alipay_payment_in_cent,
      :supay_payment_dollar_in_cent, :supay_payment_in_cent, :supay_service_amount_dollar_in_cent, :supay_service_amount_in_cent,
      :original_freight_in_cent, :freight_cost_in_cent, :gst_amount_in_cent,
      :max_cost_integral_amount_in_cent, :gift_card_amount_in_cent, :payment_without_gift_card_in_cent, :final_amount_without_gift_card_in_cent, :final_amount_with_gift_card_in_cent,
      :refunded_amount_in_cent, :strikethrough_amount_in_cent, :actually_order_items_amount_in_cent,
      :vm_credit_card_service_amount_in_cent, :unionpay_credit_card_service_amount_in_cent, :apple_pay_service_amount_in_cent, :cba_apple_pay_service_amount_in_cent,
      :cba_google_pay_service_amount_in_cent, :supay_alipay_service_amount_dollar_in_cent, :supay_wechat_service_amount_dollar_in_cent, :omipay_wechat_service_amount_dollar_in_cent, :omipay_alipay_service_amount_dollar_in_cent,
      :deliver_to_door_service_fee_in_cent, :eligible_for_free_gift_amount_in_cent,
      :stripe_credit_card_service_amount_in_cent, :stripe_google_pay_service_amount_in_cent, :stripe_apple_pay_service_amount_in_cent,
      :stripe_credit_card_payment_in_cent, :stripe_google_pay_payment_in_cent, :stripe_apple_pay_payment_in_cent, :service_amount_aud_in_cent,
      :ae_gst_amount_in_cent, :box_regulation_fee_in_cent, :time_period_fee_in_cent, :long_distance_fee_in_cent, :per_box_charge_in_cent, :original_freight_total_in_cent,
      :package_service_fee_in_cent, :package_service_discount_in_cent, :original_package_service_fee_in_cent, :value_added_service_fee_in_cent

    enum delivery_type: { merchant_delivery: 1, express: 2, self_pick: 3, virtual_delivery: 4 }

    enum status: {
      wait_buyer_pay: 1,
      wait_seller_send_goods: 2,
      wait_buyer_confirm_goods: 3,
      refunding: 4,
      trade_finished: 5,
      trade_closed: 6,
      buyer_confirm_goods: 7,
      apply_refund: 8,
      risk_pay: 9,
      live_top_confirm: 10 # 直播置顶订单需要待确认，确认通过后才能变为待发货
    }

    # 同步 wms 状态
    enum sync_status: {
      pending: 1,    # 待管理员确认订单
      confirmed: 2,  # 待同步到 wms
      synced: 3,      # 已同步到 wms
      stockout: 4
    }

    # 订单来源
    enum channel: {
      mini_program: 1,
      app: 2,
      web: 3
    }

    # 地址房屋类型
    enum address_housing_type: {
      house: 1, # 住宅
      apartment: 2, # 公寓
      office: 3, # 公司
    }

    aasm :sync_status, column: :sync_status, enum: true, requires_lock: true do
      state :pending, initial: true
      state :confirmed
      state :synced
      state :stockout

      event :sync do
        transitions from: :confirmed, to: :synced
      end

      event :sellout, after_commit: [:send_order_stockout_message, :send_order_stockout_notification, :send_order_stockout_email] do
        transitions from: [:confirmed, :synced],
                    to: :stockout,
                    success: [
                      :auto_apply_refund
                    ]
      end
    end

    aasm :status, column: :status, enum: true, requires_lock: true do
      state :wait_buyer_pay, initial: true
      state :risk_pay
      state :wait_seller_send_goods
      state :wait_buyer_confirm_goods
      state :refunding
      state :trade_finished
      state :trade_closed
      state :buyer_confirm_goods
      state :apply_refund
      state :live_top_confirm

      event :risk do
        transitions from: :wait_buyer_pay,
                    to: :risk_pay
      end

      # 两个流程:
      # 1. 直播间下单，先变为live_top_confirm，后台确认后变为wait_seller_send_goods
      # 2. 正常下单，直接变为wait_seller_send_goods
      # 但上面两种情况都是算下单成功
      event :pay, after_commit: [:after_paid_actions, :additional_pay_success_callbacks, :send_order_paid_notice] do
        transitions from: :wait_buyer_pay,
                    to: :live_top_confirm,
                    guard: :live_top
        transitions from: :risk_pay,
                    to: :live_top_confirm,
                    guard: :live_top,
                    success: [:enqueue_notify_risk_order_result_job]

        transitions from: :wait_buyer_pay,
                    to: :wait_seller_send_goods
        transitions from: :risk_pay,
                    to: :wait_seller_send_goods,
                    success: [:enqueue_notify_risk_order_result_job]
      end

      event :live_top_confirmed do
        transitions from: :live_top_confirm,
                    to: :wait_seller_send_goods
      end

      event :apply do
        transitions from: [:wait_seller_send_goods],
                    to: :apply_refund
      end

      event :deliver, after_commit: [:send_deliver_wechat_template_message] do
        transitions from: :wait_seller_send_goods,
                    to: :wait_buyer_confirm_goods,
                    after: [:update_delivered_at, :enqueue_confirm_goods_job]
      end

      event :refund, after_commit: [:withdraw_order_paid_integral, :enqueue_refund_job_with_amount, :send_drawback_wechat_template_message, :refund_child_orders] do
        transitions from: [:live_top_confirm, :wait_seller_send_goods, :wait_buyer_confirm_goods, :apply_refund],
                    to: :refunding
      end

      event :receive do
        transitions from: [:wait_buyer_confirm_goods],
                    to: :buyer_confirm_goods,
                    after: [:update_confirmed_at, :enqueue_finish_order_job, :generate_and_assign_gift_coupon_to_user, :generate_and_assign_pool_gift_coupons_to_user]
      end

      event :finish do
        transitions from: [:wait_buyer_confirm_goods, :buyer_confirm_goods, :wait_seller_send_goods],
                    to: :trade_finished,
                    after: [:update_finished_at, :reward_order_finished_integral, :reward_inviter]
      end

      event :refinish do
        transitions from: [:buyer_confirm_goods],
                    to: :trade_finished,
                    after: [:update_finished_at]
      end

      event :close, after_commit: [:after_closed_actions] do
        transitions from: [:wait_buyer_pay, :refunding],
                    to: :trade_closed
        transitions from: [:risk_pay],
                    to: :trade_closed,
                    success: [:enqueue_notify_risk_order_result_job, :refund_child_orders] # 风险支付订单不通过审核关闭，子订单也要退款
      end

      event :refuse, after_commit: [:update_is_sent_but_status_not_show_to_false, :update_sync_status_after_refuse] do
        transitions from: :apply_refund,
                    to: :wait_buyer_confirm_goods,
                    guard: :is_sent_but_status_not_show
        transitions from: :apply_refund,
                    to: :wait_seller_send_goods
      end
    end

    # association macros
    belongs_to :user
    # TODO: remove order.province
    belongs_to :province, optional: true
    belongs_to :self_pick_up, optional: true
    belongs_to :coupon, optional: true
    belongs_to :gift_card_coupon, optional: true
    belongs_to :store
    belongs_to :gift_coupon_template, class_name: "MagicBean::CouponTemplate", optional: true
    belongs_to :promo_code, optional: true
    belongs_to :delivery_time, optional: true
    belongs_to :delivery_time_period_setting, optional: true
    has_many :order_items
    has_many :order_items_sort_by_amount, -> { order(amount_in_cent: :desc) }, class_name: "MagicBean::OrderItem"
    has_many :stock_keeping_units, through: :order_items
    has_many :items, through: :order_items
    has_many :comments, through: :order_items
    has_many :logistics
    has_many :after_sales
    accepts_nested_attributes_for :order_items
    has_one :invoice
    has_many :payments, dependent: :destroy, as: :paymentable
    has_many :integral_records, as: :targetable
    with_options class_name: "MagicBean::IntegralRecord", as: :targetable do
      has_many :order_paid_integral_records, -> { order_paid }
      has_many :order_finished_integral_records, -> { order_finished }
    end
    has_many :operation_records, dependent: :destroy, as: :operatable
    has_one :order_invoice, dependent: :destroy
    belongs_to :warehouse_order, optional: true
    has_many :ae_drop_shipper_orders, dependent: :destroy

    # validation macros
    validates_presence_of :no, :order_items
    validates_presence_of :receiver_properties, unless: -> { is_preview || virtual_delivery? }
    validates :freight_in_cent, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :quantity, numericality: { less_than_or_equal_to: MAX_SKU_QUANTITY_PER_ORDER }

    validate :wait_buyer_pay_order_max_count, on: :create
    validate :check_buy_quota, on: :create
    validate :check_cost_integral, on: :create
    validate :check_delivery_type, on: :create
    validate :child_order_cannot_user_coupon_and_integral, on: :create
    # FIXME: 为了兼容旧版本，到时可能需要先取消self_pick的校验，等和客户沟通完再看怎么处理这里
    validate :check_delivery_time, on: :create, if: -> { self_pick? || merchant_delivery? }
    validate :check_merchant_delivery_address, on: :create, if: :merchant_delivery?
    validate :check_receiver_values, on: :create, if: -> { !is_preview && self_pick? }
    validate :check_user_is_blocked, on: :create
    validate :receiver_tel_number_not_in_blacklist, on: :create
    validate :all_order_items_gift_card_coupon_enabled, on: :create
    validate :check_order_is_overweight, on: :create
    validates_length_of :buyer_message, maximum: 120, allow_blank: true, on: :create

    # callbacks
    before_validation :generate_order_no, :delete_order_item_which_quantity_was_zero, on: :create
    after_commit :enqueue_close_order_job, :enqueue_push_order_wait_for_pay_job, on: :create
    after_create :remove_shopping_cart_items, :decrease_inventory!, :increase_sales_count!,
                 :set_coupon_used, :spend_member_available_integral,
                 :set_gift_card_coupon_used_amount, :enqueue_check_omipay_paid_job, :enqueue_check_supay_paid_job, :enqueue_check_stripe_paid_job
    after_create :pay_order, if: :payment_in_cent_eql_zero?
    after_commit :send_apply_refund_email_to_admin_users, if: :saved_change_to_apply_reason?, on: :update
    after_commit :reset_order_date_analysis, :enqueue_set_order_confirmed_job, if: :saved_change_to_delivery_date?, on: :update
    before_create :check_order_items_real_price_and_display_price, :try_set_express_carrier

    after_initialize :set_default_delivery_type, :set_default_value, :calculate_order_amount

    delegate :nickname, :member_mobile, :member, :avatar, :aus_mp_open_id, :locale, to: :user, prefix: true
    delegate :id, to: :invoice, prefix: true
    delegate :name, to: :store, prefix: true
    delegate :display_cba_credit_card_service, :display_unionpay_credit_card_service, :display_omipay_wechat_service, :display_omipay_alipay_service, :display_supay_wechat_service, :display_supay_alipay_service, :display_apple_pay_service, :display_cba_apple_pay_service, :display_cba_google_pay_service, :display_stripe_credit_card_service, :display_stripe_google_pay_service, :display_stripe_apple_pay_service, to: :order_payment_setting, allow_nil: true
    delegate :no, to: :warehouse_order, prefix: true, allow_nil: true

    # other macros
    ransacker :receiver_name do |parent|
      # TODO 也需要检索到 last_name
      Arel::Nodes::InfixOperation.new("->", parent.table[:receiver_properties], Arel::Nodes.build_quoted("first_name"))
    end
    ransacker :receiver_tel_number do |parent|
      Arel::Nodes::InfixOperation.new("->", parent.table[:receiver_properties], Arel::Nodes.build_quoted("tel_number"))
    end
    ransacker :payment_in_yuan do |parent|
      Arel.sql("paid_at IS NULL, payment_in_cent")
    end
    ransacker :status, formatter: proc { |v| statuses[v] }
    ransacker :sync_status, formatter: proc { |v| sync_statuses[v] }
    ransacker :delivery_type, formatter: proc { |v| delivery_types[v] }
    ransacker :channel, formatter: proc { |v| channels[v] }

    def logistic_nos
      logistics.pluck(:no)
    end

    # 下单前redis会锁订单上限，无需在支付后再去统计订单上限
    def after_paid_actions
      transaction do
        update_statistical_data
        set_paid_at
        reward_order_paid_integral
        send_new_order_email_to_admin_users
        update_new_user_to_false
      end
      enqueue_set_order_confirmed_job
      increase_preferential_pool_sku_quantity
      sync_to_aliexpress
    end

    def after_closed_actions
      transaction do
        increase_inventory!
        decrease_sales_count!
        release_coupon
        release_promo_code
        return_used_integral
        release_gift_card_coupon
        additional_close_success_callbacks
        release_counter_from_redis
      end
      decrease_preferential_pool_sku_quantity
    end

    # 订单小于 $1000 时自动确认订单
    def enqueue_set_order_confirmed_job
      # 跨境购订单不同步WMS
      return if ae_drop_shipper

      # 根据用户选的配送时间，提前一天自动确认
      if express?
        # 快递会是当天就确认的，所以要先判断现在日期是否跟delivery_date相同
        cutoff_time = "#{delivery_date} #{current_store_cutoff_time_string}".in_time_zone(order_store_time_zone)
        cutoff_time = cutoff_time.yesterday if delivery_date.to_date != Date.current
        confirm_time = cutoff_time + CONFIRM_ORDER_TIME_AFTER_CUTOFF_TIME
      else
        cutoff_time = "#{delivery_date} #{current_store_cutoff_time_string}".in_time_zone(order_store_time_zone).yesterday
        confirm_time = cutoff_time + CONFIRM_ORDER_TIME_AFTER_CUTOFF_TIME

        # 如果是直播间置顶订单，在下单后一天中午12点发送订单待确认推送，如果配送时间为明天，则今天中午12点发
        live_top_confirm_time = if Date.tomorrow.to_s == delivery_date.to_s
                                  "#{Date.current} 12:00".in_time_zone(order_store_time_zone)
                                else
                                  "#{Date.tomorrow} 12:00".in_time_zone(order_store_time_zone)
                                end
        LiveTopOrderConfirmNotificationJob.set(wait_until: live_top_confirm_time).perform_later(id) if live_top
      end

      SetOrderConfirmedJob.set(wait_until: confirm_time).perform_later(id, false, cutoff_time.to_date.to_s) if final_amount_in_yuan_num < 1000
    end

    # 要比对province_name/city_name/postal_code/street_number/street
    def live_top_order_has_main_orders?
      search_params = { delivery_type: delivery_type, delivery_date: delivery_date }
      search_params[:delivery_time_period_setting_id] = delivery_time_period_setting_id if merchant_delivery?
      user.orders.wait_seller_send_goods.where(search_params)
        .where("lower(receiver_properties -> 'province_name') like :lower_province_name and lower(receiver_properties -> 'city_name') like :lower_city_name and receiver_properties -> 'postal_code' like :postal_code and lower(receiver_properties -> 'street') like :lower_street and lower(receiver_properties -> 'street_number') like :lower_street_number",
               lower_province_name: "%#{receiver_province_name&.downcase}%", lower_city_name: "%#{receiver_city_name&.downcase}%", postal_code: "%#{receiver_postal_code}%", lower_street: "%#{receiver_street&.downcase}%", lower_street_number: "%#{receiver_street_number&.downcase}%").exists?
    end

    # 判断加单，逻辑跟live_top_order_has_main_orders?有些许差别
    # 1. 只检查风险支付和待发货订单，且配送方式、配送日期相同的订单
    # 2. 过滤掉自己
    # 3. is_child为false
    # 4. 比对province_name/city_name/postal_code/street_number/street
    def has_other_parent_orders?
      # 如果是非快递的预览订单，当delivery_date为空时，需要拿available_delivery_dates的第一个
      target_date = if new_record? && is_preview && delivery_date.blank? && !express? && available_delivery_dates.present?
                      available_delivery_dates.first[:date].to_s
                    else
                      delivery_date
                    end
      user_child_or_parent_orders_without_date_condition.where(delivery_date: target_date, delivery_time_period_setting_id: delivery_time_period_setting_id).exists?
    end

    # 返回未来有母单的日期
    def parent_orders_delivery_dates
      date_hash = {}
      user_child_or_parent_orders_without_date_condition.where("delivery_date > ?", Date.current.to_s).find_each do |order|
        date_hash[order.delivery_date] ||= []
        next if order.delivery_time_period_setting_id.blank? || date_hash[order.delivery_date].include?(order.delivery_time_period_setting_id)
        date_hash[order.delivery_date] << order.delivery_time_period_setting_id
      end
      date_hash
    end

    # 获取当天所有加单子单
    def child_orders
      if merchant_delivery?
        user_child_or_parent_orders_without_date_condition(true).where(delivery_date: delivery_date, delivery_time_period_setting_id: delivery_time_period_setting_id)
      elsif self_pick?
        user_child_or_parent_orders_without_date_condition(true).where(delivery_date: delivery_date)
      else
        []
      end
    end

    # 未发货的相同地址相同配送方式的母单或子单
    # 过滤掉直播不满免邮金额订单（live_top为true）
    def user_child_or_parent_orders_without_date_condition(child = false)
      # 过滤掉当日达订单
      user.orders.where.not(id: id, type: "MagicBean::SameDayDeliveryOrder").where(status: [:risk_pay, :wait_seller_send_goods], delivery_type: delivery_type, is_child: child, live_top: false)
        .where("lower(receiver_properties -> 'province_name') like :lower_province_name and lower(receiver_properties -> 'city_name') like :lower_city_name and receiver_properties -> 'postal_code' like :postal_code and lower(receiver_properties -> 'street') like :lower_street and lower(receiver_properties -> 'street_number') like :lower_street_number",
               lower_province_name: "%#{receiver_province_name&.downcase}%", lower_city_name: "%#{receiver_city_name&.downcase}%", postal_code: "%#{receiver_postal_code}%", lower_street: "%#{receiver_street&.downcase}%", lower_street_number: "%#{receiver_street_number&.downcase}%")
    end

    def confirm_live_top_order
      return unless live_top_confirm?
      # 如果用户有相同日期的待配送订单，则将订单变为待发货，并确认订单
      if live_top_order_has_main_orders?
        live_top_confirmed!
        confirmed! if pending?
      else
        refund!
      end
    end

    def increase_preferential_pool_sku_quantity
      if pool_gifts_properties.present?
        MagicBean::PreferentialPool.increase_quantity_of_free_gift(self)
      end
    end

    # 支付成功才会把quantity加到given_quantity上，所以关闭订单的时候需要是支付成功的订单，才执行这个方法
    def decrease_preferential_pool_sku_quantity
      if paid_at? && pool_gifts_properties.present?
        MagicBean::PreferentialPool.decrease_quantity_of_free_gift(self)
      end
    end

    # 用户下单后通知管理员
    def send_new_order_email_to_admin_users
      OrderMailer.with(order: self).new_order.deliver_later unless Rails.env.development?
    end

    # 最晚支付时间/订单关闭时间
    def latest_payment_time
      @latest_payment_time ||= created_at.try(:+, ClOSE_ORDER_TIME)
    end

    # 订单完成时间
    def latest_confirm_time
      delivered_at.try(:+, CONFIRM_GOODS_TIME)
    end

    # 金币预计入账时间
    def estimated_settled_time_of_integral
      confirmed_at.try(:+, FINISH_ORDER_TIME)
    end

    # 计算应付金额
    def calculate_payment_amount(calculate_cost_integral = true)

      self.total_payment_in_cent = amount_in_cent

      if active_pools.present? && (active_pools["discount"].present? || active_pools["reduction"].present?)
        self.total_payment_in_cent -= pool_discount_amount_in_cent
      end

      # 计算商品价格
      self.total_payment_in_cent = coupon.calculate_discount_payment(self).ceil if coupon && coupon.item?

      # 计算运费
      # 1. 计算初始运费
      # 2. 若有运费券的话则计算优惠后运费
      calculate_freight

      # 此时的freight_in_cent是优惠券的总运费 = 基础运费 + 指定时间运费 + 远距离途费
      self.original_payment_in_cent = self.freight_in_cent

      if free_shipping_code == FREE_SHIPPING_CODE && self.class.can_use_free_shipping_code?(channel, user, order_store_time_zone)
        self.freight_in_cent = 0
        # promo code和free shipping code只能用一个
        self.promo_code_id = nil
      else
        # FIXME: 测试发现这里的errors是不会在order接口触发的，输入错误的code不会提示，不过活动日期已经过了，抽时间在修复
        if free_shipping_code.present? && free_shipping_code != FREE_SHIPPING_CODE
          errors.add(:base, I18n.t("error.order.invalid_free_shipping_code"))
        elsif free_shipping_code == FREE_SHIPPING_CODE && !self.class.can_use_free_shipping_code?(channel, user, order_store_time_zone)
          errors.add(:base, I18n.t("error.order.free_shipping_code_only_for_web_new_user"))
        end
        self.freight_in_cent = coupon.calculate_freight(self) if coupon && coupon.freight?
      end

      # 超出箱规费用
      if !self_pick? && current_store_site_config.order_box_regulation_settings&.dig("enabled_box_Regulation_fee")
        self.free_box_regulation_quantity = current_store_site_config.order_box_regulation_settings&.dig("free_box_quantity").to_i
        self.per_box_charge_in_cent = current_store_site_config.order_box_regulation_settings&.dig("per_box_charge_in_cent").to_i
        self.box_regulation_fee_in_cent = (box_regulation_quantity - free_box_regulation_quantity) * per_box_charge_in_cent
        self.box_regulation_fee_in_cent = 0 if box_regulation_fee_in_cent.negative?
      else
        self.box_regulation_fee_in_cent = 0
      end

      # 子单不收送货上楼服务费和包装服务费
      if is_child
        self.deliver_to_door_service_fee_in_cent = 0
        self.package_service_fee_in_cent = 0
      else
        # 送货上楼服务费
        self.deliver_to_door_service_fee_in_cent = deliver_to_door ? current_store_deliver_to_door_service_fee : 0

        # 自提、自派、邮寄都需要收包装服务费
        if (self_pick? || merchant_delivery? || express?) && current_store_site_config.order_package_settings&.dig("enabled_package_fee")
          self.original_package_service_fee_in_cent = current_store_site_config.order_package_settings&.dig("package_fee_in_cent").to_i
          self.package_service_discount_in_cent = current_store_site_config.order_package_settings&.dig("package_discount_in_cent").to_i
          self.package_service_fee_in_cent = original_package_service_fee_in_cent - package_service_discount_in_cent
          self.package_service_fee_in_cent = 0 if package_service_fee_in_cent.negative?
        end
      end
      
      self.original_payment_in_cent = original_payment_in_cent + amount_in_cent + deliver_to_door_service_fee_in_cent + box_regulation_fee_in_cent + package_service_fee_in_cent
      self.total_payment_in_cent = total_payment_in_cent + freight_in_cent + deliver_to_door_service_fee_in_cent + box_regulation_fee_in_cent + package_service_fee_in_cent
      
      # 计算最优惠优惠券无需计算金币，不然每个优惠券的max_cost_integral值都不一样，会导致传进来的cost_integral发生变化
      # 金币不能抵扣增值费
      if calculate_cost_integral
        self.cost_integral = [cost_integral.to_i, max_cost_integral].min
      end

      # 积分不可抵扣运费，所以使用积分抵扣后的价格不能抵运费
      self.payment_in_cent = total_payment_in_cent - integral_deducte_amount_in_cent

      # 礼品券使用金额不能超过订单支付金额
      self.gift_card_amount_in_cent = gift_card_coupon ? [gift_card_amount_in_cent.to_i, payment_in_cent, gift_card_coupon.unused_amount_in_cent].min : 0

      self.payment_in_cent -= gift_card_amount_in_cent

      # 跨境购订单需要计算GST金额
      if ae_drop_shipper
        gst_percent = current_store_site_config.ae_order_gst_percent.to_i
        self.ae_gst_amount_in_cent = (payment_in_cent * gst_percent / 100.0).ceil
        self.payment_in_cent += ae_gst_amount_in_cent
        self.total_payment_in_cent += ae_gst_amount_in_cent
        self.original_payment_in_cent += ae_gst_amount_in_cent
      end

      self.wechat_service_percentage = order_payment_setting.wechat_service_percentage

      # 记录当天汇率, 避免后续计算汇率不相同
      # 预计支付rmb可以比实际高点，低了会让用户觉得多付，omipay和supay支付成功后有返回汇率，会重新更新aud_to_cny_exchange_rate
      self.aud_to_cny_exchange_rate = [::Omipay::Api.rate, ::Supay::Api.rate(SUPAY_WECHAT_KEY), ::Supay::Api.rate(SUPAY_ALIPAT_KEY)].compact.max
      self.wechat_payment_in_cent = (wechat_payment_dollar_in_cent * aud_to_cny_exchange_rate).ceil
      self.actually_amount_in_cent = payment_in_cent

      if no_transaction_fee? || !vm_credit_card_service_percentage.positive?
        self.credit_card_service_percentage = 0
        self.credit_card_payment_in_cent = payment_in_cent
      else
        # 默认为VM信用卡手续费
        self.credit_card_service_percentage = vm_credit_card_service_percentage
        self.credit_card_payment_in_cent = vm_credit_card_payment_in_cent
      end
    end

    # coupon discount amount
    # 只计算coupon
    def discount_amount_in_cent
      if coupon && coupon.freight?
        original_freight_in_cent - freight_in_cent
      else
        original_payment_in_cent - total_payment_in_cent - pool_discount_amount_in_cent
      end
    end

    def pool_discount_amount_in_cent
      arr = ((active_pools["discount"] || []) + (active_pools["reduction"] || [])).map { |pool| pool["discount_amount_in_cent"] }
      arr.blank? ? 0 : arr.sum
    end

    # 计算不减去礼品卡的实付金额，不包含手续费
    def payment_without_gift_card_in_cent
      payment_in_cent + gift_card_amount_in_cent
    end

    # 计算减去礼品卡的最终实付金额
    def final_amount_with_gift_card_in_cent
      if paid_at?
        final_amount_in_cent.to_i
      else
        calculate_final_amount.to_i
      end
    end

    # 计算不减去礼品卡的最终实付金额
    def final_amount_without_gift_card_in_cent
      final_amount_with_gift_card_in_cent + gift_card_amount_in_cent
    end

    # 计算coupon、金币、优惠池，不包含礼品券
    def total_discount_amount_in_cent
      original_payment_in_cent - payment_in_cent - gift_card_amount_in_cent
    end

    # 计算商品实付金额
    def actually_order_items_amount_in_cent
      item_amount = amount_in_cent - total_discount_amount_in_cent
      # 如果是运费券，item_amount需要加回优惠的金额
      if coupon && coupon.freight?
        item_amount += discount_amount_in_cent   
      end
      item_amount
    end

    # 优惠前的运费总金额
    def original_freight_total_in_cent
      original_freight_in_cent + time_period_fee_in_cent + long_distance_fee_in_cent
    end

    # 增值服务费总金额
    def value_added_service_fee_in_cent
      deliver_to_door_service_fee_in_cent + box_regulation_fee_in_cent + package_service_fee_in_cent
    end

    def credit_card_service_amount_in_cent
      actual_credit_card_service_amount_in_cent.zero? ? (payment_in_cent * credit_card_service_percentage.to_f / 100.0).ceil : actual_credit_card_service_amount_in_cent
    end

    def wechat_service_amount_in_cent
      (payment_in_cent * wechat_service_percentage / 100.0).ceil
    end

    def default_site_config
      @default_site_config ||= MagicBean::SiteConfig.default_config
    end

    def order_payment_setting
      @order_payment_setting ||= store.payment_setting
    end

    def risk_pay_enabled
      default_site_config.risk_pay_enabled
    end

    def admin_multi_lang_config(custom_locale = nil)
      @admin_multi_lang_config ||= MagicBean::MultiLangConfig.config(store_id, custom_locale || user.locale, :admin)
    end

    def vm_credit_card_service_percentage
      order_payment_setting.vm_credit_card_service_percentage
    end

    def amex_credit_card_service_percentage
      order_payment_setting.amex_credit_card_service_percentage
    end

    def unionpay_credit_card_service_percentage
      order_payment_setting.unionpay_credit_card_service_percentage
    end

    def apple_pay_service_percentage
      order_payment_setting.apple_pay_service_percentage
    end

    def cba_apple_pay_service_percentage
      order_payment_setting.cba_apple_pay_service_percentage
    end

    def cba_google_pay_service_percentage
      order_payment_setting.cba_google_pay_service_percentage
    end

    def no_transaction_fee_over_amount_in_cent
      order_payment_setting.no_transaction_fee_over_amount_in_cent
    end

    def vm_credit_card_service_amount_in_cent
      (payment_in_cent * vm_credit_card_service_percentage.to_f / 100.0).ceil
    end

    def amex_credit_card_service_amount_in_cent
      (payment_in_cent * amex_credit_card_service_percentage.to_f / 100.0).ceil
    end

    def unionpay_credit_card_service_amount_in_cent
      (payment_in_cent * unionpay_credit_card_service_percentage.to_f / 100.0).ceil
    end

    def apple_pay_service_amount_in_cent
      (payment_in_cent * apple_pay_service_percentage.to_f / 100.0).ceil
    end

    def cba_apple_pay_service_amount_in_cent
      (payment_in_cent * cba_apple_pay_service_percentage.to_f / 100.0).ceil
    end

    def cba_google_pay_service_amount_in_cent
      (payment_in_cent * cba_google_pay_service_percentage.to_f / 100.0).ceil
    end

    def enable_commweb_3ds_auth
      order_payment_setting.enable_commweb_3ds_auth
    end

    # 两个微信note小程序可能用到，先不删
    def wechat_note
      default_site_config.wechat_note
    end

    def omipay_wechat_note
      default_site_config.omipay_wechat_note
    end

    def vm_credit_card_payment_in_cent
      if no_transaction_fee?
        payment_in_cent
      else
        (payment_in_cent * (1 + vm_credit_card_service_percentage.to_f / 100.0).round(4)).round(2).ceil
      end
    end

    def unionpay_credit_card_payment_in_cent
      if no_transaction_fee?
        payment_in_cent
      else
        (payment_in_cent * (1 + unionpay_credit_card_service_percentage.to_f / 100.0).round(4)).round(2).ceil
      end
    end

    def apple_pay_payment_in_cent
      if no_transaction_fee?
        payment_in_cent
      else
        (payment_in_cent * (1 + apple_pay_service_percentage.to_f / 100.0).round(4)).round(2).ceil
      end
    end

    def cba_apple_pay_payment_in_cent
      if no_transaction_fee?
        payment_in_cent
      else
        (payment_in_cent * (1 + cba_apple_pay_service_percentage.to_f / 100.0).round(4)).round(2).ceil
      end
    end

    def cba_google_pay_payment_in_cent
      if no_transaction_fee?
        payment_in_cent
      else
        (payment_in_cent * (1 + cba_google_pay_service_percentage.to_f / 100.0).round(4)).round(2).ceil
      end
    end

    # 微信支付的支付金额 $
    def wechat_payment_dollar_in_cent
      if no_transaction_fee?
        payment_in_cent
      else
        (payment_in_cent * (1 + wechat_service_percentage / 100.0).round(4)).round(2).ceil
      end
    end

    def calculate_final_amount
      case payment_type
      when "wechat"
        wechat_payment_dollar_in_cent
      when "omipay"
        omipay_payment_dollar_in_cent
      when "supay"
        supay_payment_dollar_in_cent
      else
        credit_card_payment_in_cent
      end
    end

    def default_freight_templates
      @default_freight_templates ||= MagicBean::DefaultFreightTemplate.where(store_id: store_id)
    end

    def calculate_freight
      if delivery_type.blank?
        self.freight_in_cent = 0
        self.original_freight_in_cent = 0
        self.box_regulation_fee_in_cent = 0
        return
      end

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
      
      # 远程运费，无论固定运费、包邮，都需要算上远程运费
      self.long_distance_fee_in_cent = template_items_freights&.last.to_i
  
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
      
      # 指定时间段运费
      self.time_period_fee_in_cent = merchant_delivery? ? delivery_time_period_setting&.freight_in_cent.to_i : 0
      
      # 基础运费
      self.original_freight_in_cent = freight_in_cent
      # 总运费
      self.freight_in_cent = freight_in_cent + long_distance_fee_in_cent + time_period_fee_in_cent

      # 当为直播间置顶订单
      # 1. 运费不为0，则将运费赋值为0
      # 2. 运费为0时，则将live_top设为false
      # 3. 邮寄订单不支持以上逻辑
      if express?
        self.live_top = false
        self.is_child = false
      else
        if live_top
          if freight_in_cent.zero?
            self.live_top = false
          else
            self.freight_in_cent = 0
          end
        elsif freight_in_cent.positive? && has_other_parent_orders?
          self.freight_in_cent = 0
          self.is_child = true
        end
      end
    end

    # 并发会引起余额脏数据，需要重新计算支付金额
    def recalculate_payment_amount
      calculate_payment_amount
      self.save
    end

    def calculate_order_amount
      return unless self.new_record?
      order_items.map(&:calculate_amount)
      self.amount_in_cent = order_items.to_a.pluck(:amount_in_cent).sum
      self.strikethrough_amount_in_cent = order_items.to_a.pluck(:strikethrough_amount_in_cent).sum
      # 筛选is_box_regulation为true的order_items数量
      self.box_regulation_quantity = order_items.to_a.select { |order_item| order_item.is_box_regulation }.pluck(:quantity).sum

      calculate_payment_amount
    end

    def after_sales_creatable?
      AFTER_SALES_CREATABLE_TYPES.include?(type) &&
        AFTER_SALES_CREATABLE_STATUSES.include?(status)
    end

    def part_refund?
      quantity != after_sales.successful.sum(:total_quantity)
    end

    def human_gifts_properties
      free_gift_text = web? ? "(Free Gift)" : "（赠品）"
      (gifts_properties || []).map do |gift|
        gift["title"] = "#{gift["title"]}#{free_gift_text}" if gift["title"].exclude?(free_gift_text)
        gift["real_price_in_yuan"] = "/"
        gift["amount_in_yuan"] = "/"
        gift
      end
    end

    def human_pool_gifts_properties
      free_gift_text = web? ? "(Free Gift)" : "（赠品）"
      (pool_gifts_properties || []).map do |gift|
        gift["title"] = "#{gift["title"]}#{free_gift_text}" if gift["title"].exclude?(free_gift_text)
        gift["real_price_in_yuan"] = "/"
        gift["amount_in_yuan"] = "/"
        gift
      end
    end

    def human_gift_coupons
      MagicBean::CouponTemplate.where(id: (pool_coupon_template_ids || []) + [gift_coupon_template_id]).map do |template|
        {
          id: template.id,
          title: template.title,
        }
      end
    end

    def receiver_name
      "#{ receiver_first_name } #{ receiver_last_name }"
    end

    # 跨境购地址姓和名不能有空格，将first_name、last_name的空格都去掉
    # first_name、last_name都不能包含特殊符号
    # 如果去空格后的first_name、last_name少于2个字符，则用x补满到2个字符
    def ae_drop_shipper_receiver_name
      tmp_first_name = receiver_first_name&.gsub(" ", "")&.gsub(/[^a-zA-Z0-9]/, "").to_s
      tmp_last_name = receiver_last_name&.gsub(" ", "")&.gsub(/[^a-zA-Z0-9]/, "").to_s
      tmp_first_name += "x" * (2 - tmp_first_name.length) if tmp_first_name.length < 2
      tmp_last_name += "x" * (2 - tmp_last_name.length) if tmp_last_name.length < 2
      "#{ tmp_first_name } #{ tmp_last_name }".strip
    end

    def human_receiver_properties
      return nil if receiver_properties.nil?
      "#{full_receiver_address} #{receiver_name} #{receiver_tel_number}"
    end

    def full_receiver_address
      return nil if receiver_properties.nil?
      "#{receiver_detail_info} #{receiver_city_name} #{receiver_province_name} #{receiver_postal_code}"
    end

    RECEIVER_PROPERTIES.each do |attr_name|
      perfix_attr_name = "receiver_#{attr_name}"
      define_method perfix_attr_name do
        @perfix_attr_name = receiver_properties&.dig(attr_name)&.strip
      end
    end

    def commentable?
      %[wait_buyer_confirm_goods trade_finished buyer_confirm_goods].include?(status) &&
        order_items.any? { |oi| !MagicBean::Comment.exists?(commentable: oi, user: user) }
    end

    def invoicable_amount_in_cent
      payment_in_cent - after_sales.effective.sum(:amount_in_cent)
    end

    def invoicable?
      %[trade_finished buyer_confirm_goods].include?(status) && invoicable_amount_in_cent.positive?
    end

    # 分类设置可开发票 和 sku营销模式不为平台 两种情况满足方可开发票
    # 网站订单检查商品所属网站分类是否不可开发票，app 和小程序订单检查原有分类是否不可开发票
    def contains_not_invoicable_items?
      (web? ?
        order_items.map(&:item).map(&:parent_web_category).compact.map(&:can_create_invoice).any?(false) :
        order_items.map(&:item).map(&:parent_category).compact.map(&:can_create_invoice).any?(false)) ||
      order_items.map(&:marketing_mode).uniq.include?("platform") ||
      order_items.map(&:stock_keeping_unit).map(&:can_create_invoice).any?(false)
    end

    def invoice_id
      invoice&.id
    end

    # 当前版本只有 eParcel
    # stockout_items [{sku: "abc", qty: 1}]
    def deliver_and_generate_logistic(logistic_no, company: "eParcel", fake: false, stockout_items: [], order_eta: nil, delivery_path: nil)
      if fake
        new_fake_logistic.save
      elsif logistic_no.present?
        # 如果是快马配送
        if warehouse_order&.kuaima_delivery?
          self.update_column :delivery_track, build_kuaima_delivery_track_url(logistic_no)
        else
          logistics.find_or_create_by(no: logistic_no, company: company)
        end
      end

      # 允许创建多个物流记录，但只执行一次已发货状态变更和发货通知
      return unless self.may_deliver?

      self.perform_aasm_event(:deliver)

      original_locale = I18n.locale
      I18n.locale = user_locale

      create_after_sale_by(stockout_items) if stockout_items.present?

      return if fake

      if user.member&.email.blank?
        wms_dispatch_sms_message(logistic_no, order_eta, delivery_path)
        wms_dispatch_notification(logistic_no, order_eta, delivery_path)
      else
        wms_dispatch_sms_message(logistic_no, order_eta, delivery_path) unless web?
        wms_dispatch_notification(logistic_no, order_eta, delivery_path)
        enqueue_send_klaviyo_email_job("send_order_fulfilled_email")
        # enqueue_send_sendgrid_email_job("fulfilled_order")
      end

      I18n.locale = original_locale
    end

    def total_quantity
      order_items.sum(:quantity)
    end

    def create_after_sale_by(stockout_items)
      after_sales_order_items =
        stockout_items.map do |stockout_item|
          next if stockout_item.blank?
          order_item =
            if stockout_item["product_id"]
              order_items.find_by(stock_keeping_unit_id: stockout_item["product_id"])
            elsif stockout_item["sku"]
              order_items.joins(:stock_keeping_unit).find_by("stock_keeping_units.no = ?", stockout_item["sku"]&.strip)
            else
              order_items.joins(:stock_keeping_unit).find_by("stock_keeping_units.barcode ILIKE ?", "%#{stockout_item["barcode"]&.strip}%")
            end

          next if order_item.nil?
          { order_item: order_item, quantity: stockout_item["qty"] }
        end.compact

      return if after_sales_order_items.blank?

      # create方法在after_sale初始化的时候，order_id为空，所以这里把order_id手动赋值
      self.after_sales.create!(
        order_id: id,
        reason: "系统发起: 部分缺货",
        after_sale_type: "refund",
        user_id: user_id,
        applicant_type: "wms",
        after_sales_order_items_attributes: after_sales_order_items
      ) if after_sales_order_items.any?

      self.update(remark: "#{remark} 系统发起售后: 部分缺货")

      send_order_part_stockout_message(after_sales_order_items)
      send_order_part_stockout_notification(after_sales_order_items)
    end

    def new_fake_logistic
      logistic = logistics.new(
        company: "eParcel",
        traces: [
          {
            "location": "WALLAN VIC",
            "description": "With Australia Post for delivery today",
            "date": "2018-01-15T08:35:02+11:00"
          },
          {
            "location": "SUNSHINE WEST VIC",
            "description": "Processed through Australia Post facility",
            "date": "2018-01-12T10:55:25+11:00"
          },
          {
            "location": "CHULLORA NSW",
            "description": "Processed through Australia Post facility",
            "date": "2018-01-11T13:22:34+11:00"
          }
        ]
      )
      logistic.generate_fake_no
      logistic
    end

    def refundable?
      is_a?(MagicBean::GrouponOrder) ? (editable? && (groupon.finished? || groupon.free?)) : editable?
    end

    # TODO: 暂时允许所有待发货订单退款
    def editable?
      if Rails.env.production?
        (live_top_confirm? || wait_seller_send_goods?) && (pending? || stockout?)
      else
        (live_top_confirm? || wait_seller_send_goods?) && !synced?
      end
    end

    # 管理后台直接退款
    def admin_refundable?
      refundable?
    end

    def effective_refund_amount_in_cent
      after_sales.effective.sum(:amount_in_cent)
    end

    def effective_after_sales_order_items_quantity
      MagicBean::AfterSalesOrderItem.where(after_sale_id: after_sales.effective.pluck(:id)).sum(:quantity)
    end

    # 返回赠品stock_keeping_units数组
    def gifts
      @gifts ||= gifts_properties.to_a.map do |gift|
        {
          sku: MagicBean::StockKeepingUnit.find_by(id: gift["stock_keeping_unit_id"]),
          quantity: gift["quantity"]
        }
      end.compact
    end

    def pool_gifts
      @pool_gifts ||= pool_gifts_properties.to_a.map do |gift|
        {
          sku: MagicBean::StockKeepingUnit.find_by(id: gift["stock_keeping_unit_id"]),
          quantity: gift["quantity"]
        }
      end.compact
    end

    def gift_order_items
      @gift_order_items ||= gifts.map do |gift|
        MagicBean::OrderItem.new(gift[:sku].to_order_item_json(gift[:quantity], 0, nil, true).first)
      end
    end

    def pool_gift_order_items
      @pool_gift_order_items ||= pool_gifts.map do |gift|
        MagicBean::OrderItem.new(gift[:sku].to_order_item_json(gift[:quantity], 0, nil, true).first)
      end
    end

    def gifts_sku_ids
      gifts_properties.to_a.pluck("stock_keeping_unit_id")
    end

    def pool_gifts_sku_ids
      pool_gifts_properties.to_a.pluck("stock_keeping_unit_id")
    end

    def drawback!
      perform_aasm_event(:close)
    end

    def union_pay?
      last_union_pay_payment.present?
    end

    def union_pay_response
      last_union_pay_payment.response if union_pay?
    end

    # 最后一个银联支付
    def last_union_pay_payment
      payments.where(type: "MagicBean::UnionPayPayment").charge_payment_type.last
    end

    # 支付完成的纪录
    def completed_charge_payment
      payments.charge_payment_type.completed.first
    end

    def completed_charge_payment_channel
      completed_charge_payment&.channel || channel
    end

    def original_spent_channel
      integral_records.spent.first&.channel || channel
    end

    def short_channel
      channel.gsub("_program", "")
    end

    def items_available_delivery_types
      @items_available_delivery_types ||= items_available_delivery_types_query
    end

    def items_available_delivery_types_query
      items_delivery_types = MagicBean::Item.where(id: order_items.map(&:item_id)).pluck(:delivery_type)
      available_delivery_types = self.class.delivery_types.keys
      items_delivery_types.each do |item_delivery_types|
        available_delivery_types = available_delivery_types & item_delivery_types
      end
      available_delivery_types
    end

    def available_delivery_time
      return unless merchant_delivery? || self_pick?

      if merchant_delivery?
        @available_delivery_time ||= current_delivery_area&.delivery_time
      else
        @available_delivery_time ||= self_pick_up
      end
    end

    def title
      no
    end

    def order_name
      raise "子类覆盖此方法"
    end

    def actual_amount_for_display
      case payment_type
      when "credit_card", "union_pay", "stripe_credit_card", "stripe_apple_pay", "stripe_google_pay"
        "$#{credit_card_payment_in_yuan}"
      when "wechat"
        "￥#{wechat_payment_in_yuan}"
      when "omipay"
        "￥#{omipay_payment_in_yuan}"
      when "supay"
        "￥#{supay_payment_in_yuan}"
      when "apple_pay"
        "$#{apple_pay_payment_in_yuan}"
      when "cba_apple_pay"
        "$#{cba_apple_pay_payment_in_yuan}"
      when "cba_google_pay"
        "$#{cba_google_pay_payment_in_yuan}"
      else
        "0"
      end
    end

    def calculate_order_items_display_price
      order_items.each do |item|
        item.calculate_display_price
      end
    end

    # 获取最大金额的order_item, 该方法用户order_item创建之前调用
    def sort_order_items_by_amount
      @sort_order_items ||= order_items.sort_by { |item| -item.amount_in_cent }
    end

    # 需要测试确定是否要重写
    def check_order_items_real_price_and_display_price
      # 未算上金币、礼品卡、运费、增值服务费（送货上门和箱规费用）、ae_gst_amount的实付金额：total_payment_in_cent - ae_gst_amount_in_cent - freight_in_cent - deliver_to_door_service_fee_in_cent - box_regulation_fee_in_cent - package_service_fee_in_cent
      rest_amount = order_items_real_amount - (total_payment_in_cent - ae_gst_amount_in_cent - freight_in_cent - deliver_to_door_service_fee_in_cent - box_regulation_fee_in_cent - package_service_fee_in_cent)
      if rest_amount != 0
        # 需要跟order_item的实际总额比较，而非real_price_in_cent
        # 这里不能用order_items_sort_by_amount，因为创建时order_items还没创建，使用order_items_sort_by_amount会获取到空数组
        sort_order_items = sort_order_items_by_amount

        selected_item = if coupon&.item_ids.present?
                          sort_order_items.select { |item| coupon.item_ids.include?(item.item_id) && item.real_amount_in_cent > rest_amount }.first
                        else
                          sort_order_items.select { |item| item.real_amount_in_cent > rest_amount }.first
                        end
        if selected_item.present?
          selected_item.real_amount_in_cent -= rest_amount
          selected_item.real_price_in_cent -= (rest_amount.to_f / selected_item.quantity).floor
        else
          @@special_logger.debug "check_order_items_real_price_and_display_price error:"
          @@special_logger.debug self.attributes
          @@special_logger.debug self.order_items.to_json
          @@special_logger.debug "coupon is: #{self.coupon.to_json}"
        end
      end

      calculate_order_items_display_price
      check_order_items_display_price
      
      # 算出real_price之后再算均摊的礼品卡和金币
      set_order_items_gift_card_amount
      set_order_items_cost_integral
      set_order_items_ae_gst_amount
    end

    def check_order_items_display_price
      order_items_display_amount = order_items.inject(0) { |sum, item| sum + item.real_display_amount_in_cent }
      # 未算上礼品卡、运费、AE GST金额的实付金额：payment_without_gift_card_in_cent - ae_gst_amount_in_cent - freight_in_cent - deliver_to_door_service_fee_in_cent - box_regulation_fee_in_cent - package_service_fee_in_cent
      rest_amount = order_items_display_amount - (payment_without_gift_card_in_cent - ae_gst_amount_in_cent - freight_in_cent - deliver_to_door_service_fee_in_cent - box_regulation_fee_in_cent - package_service_fee_in_cent)
      return if rest_amount.zero?

      # 优惠券平摊金额后，可能会除不尽，所以需要把剩余的优惠金额减到金额最大的order_item上
      selected_item = sort_order_items_by_amount.select { |item| item.real_display_amount_in_cent > rest_amount }.first

      if selected_item.present?
        selected_item.display_price_in_cent -= (rest_amount.to_f / selected_item.quantity).floor
      else
        @@special_logger.debug "check_order_items_display_price error:"
        @@special_logger.debug self.attributes
        @@special_logger.debug self.order_items.to_json
        @@special_logger.debug "coupon is: #{self.coupon.to_json}"
      end
    end

    def order_items_real_amount
      order_items.inject(0) { |sum, item| sum + item.real_amount_in_cent }
    end

    def refunded_amount_in_cent
      payment_in_cent - actually_amount_in_cent
    end

    def payment_type_name
      case payment_type
      when "wechat"
        "小程序微信支付"
      when "omipay"
        if omipay_platform == "WECHATPAY"
          "Omipay微信支付"
        elsif omipay_platform == "ALIPAYONLINE"
          "Omipay支付宝"
        else
          "Omipay"
        end
      when "credit_card"
        "信用卡"
      when "union_pay"
        "银联"
      when "apple_pay"
        "银联ApplePay"
      when "cba_apple_pay"
        "CBA ApplePay"
      when "cba_google_pay"
        "CBA GooglePay"
      when "supay"
        if supay_platform == "WXPAY"
          "Supay微信支付"
        elsif supay_platform == "ALIPAY"
          "Supay支付宝"
        else
          "Supay"
        end
      when "stripe_credit_card"
        "Stripe信用卡"
      when "stripe_google_pay"
        "Stripe GooglePay"
      when "stripe_apple_pay"
        "Stripe ApplePay"
      else
        ""
      end
    end

    def payment_in_yuan_aud_for_export
      case payment_type
      when "credit_card", "union_pay", "stripe_credit_card", "stripe_apple_pay", "stripe_google_pay"
        credit_card_payment_in_yuan_num
      when "wechat"
        wechat_payment_dollar_in_yuan_num
      when "omipay"
        omipay_payment_dollar_in_yuan_num
      when "supay"
        supay_payment_dollar_in_yuan_num
      when "apple_pay"
        apple_pay_payment_in_yuan_num
      when "cba_apple_pay"
        cba_apple_pay_payment_in_yuan_num
      when "cba_google_pay"
        cba_google_pay_payment_in_yuan_num
      else
        payment_in_yuan_num
      end
    end

    def service_amount_aud_in_cent
      case payment_type
      when "credit_card", "union_pay", "apple_pay", "cba_apple_pay", "cba_google_pay", "stripe_credit_card", "stripe_apple_pay", "stripe_google_pay"
        credit_card_service_amount_in_cent
      when "wechat"
        wechat_service_amount_in_cent
      when "omipay"
        omipay_service_amount_dollar_in_cent
      when "supay"
        supay_service_amount_dollar_in_cent
      else
        0
      end
    end

    def service_amount_aud_for_export
      case payment_type
      when "credit_card", "union_pay", "apple_pay", "cba_apple_pay", "cba_google_pay", "stripe_credit_card", "stripe_apple_pay", "stripe_google_pay"
        credit_card_service_amount_in_yuan_num
      when "wechat"
        wechat_service_amount_in_yuan_num
      when "omipay"
        omipay_service_amount_dollar_in_yuan_num
      when "supay"
        supay_service_amount_dollar_in_yuan_num
      else
        0
      end
    end

    def payment_in_yuan_cny_for_export
      case payment_type
      when "wechat"
        wechat_payment_in_yuan_num
      when "omipay"
        omipay_payment_in_yuan_num
      when "supay"
        supay_payment_in_yuan_num
      else
        0
      end
    end

    def reopen_after_sale
      if trade_finished?
        update_attribute :status, :buyer_confirm_goods
        enqueue_refinish_order_job
      else
        self.errors.add :base, I18n.t("error.order.order_status_can_not_open_after_sale")
      end
    end

    # 优惠力度最大的优惠券
    def most_favorable_coupon
      return @most_favorable_coupon if @most_favorable_coupon
      coupons = user.usable_coupons_for(self, self.channel).map do |coupon|
        self.coupon_id = coupon.id
        calculate_payment_amount(false)
        { id: coupon.id, order_total_payment: self.total_payment_in_cent }
      end
      @most_favorable_coupon = coupons.sort_by { |coupon| coupon[:order_total_payment] }.first
    end

    # code存在且不为0时，根据code返回优惠券；
    # code为0且is_preview为true时，返回力度最大的优惠券;
    # code不存在时返回nil
    def use_coupon(code, is_preview)
      if code.present?
        usable_coupons = user.coupons.where(store: [nil, store_id]).usable
        if code != "0"
          target_coupon = usable_coupons.find_by(code: code)
          if target_coupon && target_coupon.invalid_for_delivery?(delivery_type)
            nil
          else
            target_coupon
          end
        elsif is_preview
          usable_coupons.find(most_favorable_coupon[:id]) if most_favorable_coupon
        end
      end
    end

    def admin_detail_url
      domain = Rails.application.credentials.dig(Rails.env.to_sym, :domain)
      order_type = if virtual_delivery?
                     "virtual_orders"
                   else
                     self.is_a?(MagicBean::NormalOrder) ? "normal_orders" : "groupon_orders"
                   end
      "#{domain}/admin/stores/all/#{order_type}/#{id}"
    end

    def order_store_time_zone
      @order_store_time_zone ||= store.current_time_zone
    end

    def all_order_items_gift_card_coupon_enabled
      return true if gift_card_coupon.nil?

      gift_card_coupon_enabled = true
      order_items.each do |oi|
        unless oi.gift_card_enabled
          gift_card_coupon_enabled = false
          break
        end
      end

      self.errors.add(:base, I18n.t("error.order.gift_card_disabled")) unless gift_card_coupon_enabled
    end

    def gst_amount_in_cent
      @gst_amount_in_cent ||= order_items.sum(&:gst_amount_in_cent)
    end

    def no_transaction_fee?
      no_transaction_fee_over_amount_in_cent.present? && payment_in_cent >= no_transaction_fee_over_amount_in_cent
    end

    def warehouse_order_uniq_hash
      {
        sync_status: :confirmed,
        store_id: store_id,
        user_id: user_id,
        delivery_type: delivery_type,
        delivery_date: delivery_date,
        prefer_time: prefer_time,
        delivery_time_period_setting_id: delivery_time_period_setting_id,
        channel: channel,
        receiver_properties: receiver_properties,
        same_day_delivery: type == "MagicBean::SameDayDeliveryOrder" # 当日达订单和其他订单要分开合并仓储订单
      }
    end

    def order_items_with_gifts
      @order_items_with_gifts ||= (order_items.to_a << (gift_order_items + pool_gift_order_items)).flatten
    end

    def can_create_warehouse_order?
      warehouse_order_id.nil? && confirmed? && wait_seller_send_goods? && delivery_date.present? && type.in?(%w[MagicBean::NormalOrder MagicBean::GrouponOrder MagicBean::SameDayDeliveryOrder])
    end

    # 参与满赠活动的商品总金额（不包含礼品卡金额）
    def eligible_for_free_gift_amount_in_cent
      tmp_amount = order_items.to_a.select { |item| !item.not_eligible_for_free_gift }.pluck(:amount_in_cent).sum

      # 使用了礼品卡，且礼品卡不参与满赠活动时需要减去礼品卡金额
      if gift_card_coupon && gift_card_coupon.not_eligible_for_free_gift
        tmp_amount -= gift_card_amount_in_cent
      end

      tmp_amount.positive? ? tmp_amount : 0
    end

    def set_order_items_service_amount(total_service_amount_in_cent)
      if total_service_amount_in_cent.to_i.positive?
        service_amount_in_cents = self.order_items.map do |order_item|
          order_item.service_amount_in_cent = (order_item.amount_in_cent / amount_in_cent.to_f * total_service_amount_in_cent).floor
        end
        rest_service_amount = total_service_amount_in_cent - service_amount_in_cents.sum
  
        # 如果有余数，则将余数加到金额最大的订单项
        if rest_service_amount.positive?
          sort_order_items_by_amount.first.service_amount_in_cent += rest_service_amount
        end

        save(validate: false)
      end
    end

     # 将金币均分到所有订单项
     def set_order_items_cost_integral
      if cost_integral.positive?
        cost_integrals = self.order_items.map do |order_item|
          order_item.cost_integral = (order_item.amount_in_cent / amount_in_cent.to_f * cost_integral).floor
        end
        rest_cost_integral = cost_integral - cost_integrals.sum

        # 如果有余数，则将余数加到金额最大的订单项，但如果金币 + 金币余数 + 礼品卡金额 大于实付金额，则用下一个订单项
        if rest_cost_integral.positive?
          selected_item = sort_order_items_by_amount.select { |item| item.gift_card_amount_in_cent + exchange_integral_to_aus_dollar(item.cost_integral + rest_cost_integral) <= item.real_amount_in_cent }.first
          selected_item.cost_integral += rest_cost_integral if selected_item
        end
      end
    end

    # 将礼品卡金额均分到所有订单项
    def set_order_items_gift_card_amount
      # 现金优先抵扣运费，但现金不足时，部分礼品卡需要用来运费、增值服务费
      # 计算出除去运费、增值服务费的礼品卡金额 + 现金总和
      total_amount = gift_card_amount_in_cent + payment_in_cent - freight_in_cent - deliver_to_door_service_fee_in_cent - box_regulation_fee_in_cent - package_service_fee_in_cent
      # gift_card_amount_in_cent和total_amount的最小值为除去运费的礼品卡金额
      tmp_gift_card_amount_in_cent = [total_amount, gift_card_amount_in_cent].min

      if tmp_gift_card_amount_in_cent.positive?
        gift_card_amount_in_cents = self.order_items.map do |order_item|
          order_item.gift_card_amount_in_cent = (order_item.amount_in_cent / amount_in_cent.to_f * tmp_gift_card_amount_in_cent).floor
        end
        rest_gift_card_amount_in_cent = tmp_gift_card_amount_in_cent - gift_card_amount_in_cents.sum

        # 如果有余数，则将余数加到金额最大的订单项，但如果金币+礼品卡金额大于实付金额，则用下一个订单项
        if rest_gift_card_amount_in_cent.positive?
          selected_item = sort_order_items_by_amount.select { |item| item.gift_card_amount_in_cent + rest_gift_card_amount_in_cent + exchange_integral_to_aus_dollar(item.cost_integral) <= item.real_amount_in_cent }.first
          selected_item.gift_card_amount_in_cent += rest_gift_card_amount_in_cent if selected_item
        end
      end
    end

    # 将gst金额均分到所有订单项
    def set_order_items_ae_gst_amount
      if ae_gst_amount_in_cent.positive?
        ae_gst_amounts = self.order_items.map do |order_item|
          order_item.ae_gst_amount_in_cent = (order_item.amount_in_cent / amount_in_cent.to_f * ae_gst_amount_in_cent).floor
        end
        rest_ae_gst_amount_in_cent = ae_gst_amount_in_cent - ae_gst_amounts.sum

        # 如果有余数，则将余数加到金额最大的订单项，但如果 + 金币余数 + 礼品卡金额 大于实付金额，则用下一个订单项
        if rest_ae_gst_amount_in_cent.positive?
          sort_order_items_by_amount.first.ae_gst_amount_in_cent += rest_ae_gst_amount_in_cent
        end
      end
    end

    # 生成仓储订单
    def generate_warehouse_order(independent = false)
      return unless can_create_warehouse_order?

      if express?
        new_warehouse_order_uniq_hash = self.warehouse_order_uniq_hash.merge({ deliver_to_door: deliver_to_door, authority_to_leave: authority_to_leave })
        wo = MagicBean::WarehouseOrder.create(new_warehouse_order_uniq_hash)
      else
        # 如果independent为true, 则生成独立仓储订单
        if independent
          wo = MagicBean::WarehouseOrder.new(self.warehouse_order_uniq_hash)
        else
          wo = MagicBean::WarehouseOrder.find_or_initialize_by(self.warehouse_order_uniq_hash)
        end

        if wo.new_record?
          wo.deliver_to_door = deliver_to_door
          wo.authority_to_leave = authority_to_leave
        else
          # authority_to_leave 有多个值 —> 取 false
          # deliver_to_door 有多个值 —> 取 true
          wo.deliver_to_door = true if wo.deliver_to_door != deliver_to_door
          wo.authority_to_leave = false if wo.authority_to_leave != authority_to_leave
        end
        wo.save
      end
      
      wo.append(self)
      if wo.satisfy_kuaima_delivery?
        kuaima_delivery_count = MagicBean::WarehouseOrder.where(delivery_date: delivery_date, express_carrier: MagicBean::Order::KUAIMA_COMPANY).size
        if kuaima_delivery_count < MagicBean::SiteConfig.default_config.kuaima_delivery_max_count.to_i
          wo.update_column :express_carrier, MagicBean::Order::KUAIMA_COMPANY
        end
      else
        wo.update_column :express_carrier, nil
      end
    end

    def sync_ae_order_trackings
      return if ae_order_list.blank?

      ae_order_list.each do |ae_order_no|
        retry_times = 2
        begin
          response = Aliexpress::Api.get_order_tracking(ae_order_no)
          error_response = response&.body.dig("error_response")

          if error_response.present?
            raise error_response.dig("sub_msg") || error_response.dig("msg") || "同步AE订单跟踪信息失败"
          else
            result = response.body.dig("result")
            # 刚下单的订单，返回结果为{"result"=>{}}
            # https://openservice.aliexpress.com/doc/api.htm?spm=a2o9m.11193487.0.0.372eee0cUpbiOf#/api?cid=21038&path=aliexpress.ds.order.tracking.get&methodType=GET/POST
            # 正常返回结果为:
            # {"result"=>
            #   {"ret"=>true,
            #    "msg"=>"",
            #    "code"=>"",
            #    "data"=>
            #     {"tracking_detail_line_list"=>
            #       [{"detail_node_list"=>
            #          [{"time_stamp"=>1743630124000, "tracking_detail_desc"=>"Your package arrived at airport. Awaiting transit.", "tracking_name"=>"Shipping update"},
            #           {"time_stamp"=>1743616150000, "tracking_detail_desc"=>"Package left sorting center of origin.", "tracking_name"=>"Shipping update"},
            #           {"time_stamp"=>1743614228000, "tracking_detail_desc"=>"Package received by sorting center of origin.", "tracking_name"=>"Shipping update"},
            #           {"time_stamp"=>1743605290000, "tracking_detail_desc"=>"Package collected by carrier.", "tracking_name"=>"Shipping update"},
            #           {"time_stamp"=>1743600962000, "tracking_detail_desc"=>"Package left warehouse.", "tracking_name"=>"Order shipped"},
            #           {"time_stamp"=>1743599952744, "tracking_detail_desc"=>"Package ready to be shipped by warehouse.", "tracking_name"=>"Preparing to ship"},
            #           {"time_stamp"=>1743580980164, "tracking_detail_desc"=>"Your order is being packed", "tracking_name"=>"Preparing to ship"}],
            #         "package_item_list"=>
            #          [{"sku_desc"=>"Color:B",
            #            "quantity"=>1,
            #            "item_id"=>1005006128263488,
            #            "item_title"=>"High Pressure Long Pole Car Wash Water Gun, Household Car Wash Tool, Metal Extension Pole, Rubber Coating, Gardening Tool"}],
            #         "carrier_name"=>"AliExpress Selection Standard",
            #         "mail_no"=>"3781051111734",
            #         "eta_time_stamps"=>1744779478818}]}},
            # }
            if result.present?
              # ret为true时才是成功
              if result.dig("ret")
                logistic_traces = result.dig("data", "tracking_detail_line_list")
                # App要隐藏AE相关字眼，这里写死公司名称
                company = "International Express"
                logistic_no = logistic_traces.first.dig("mail_no")
                # TODO: 需要确认同个订单的logistic_no是否会变化
                logistic = logistics.find_or_create_by(ae_order_no: ae_order_no, company: company, no: logistic_no)
                logistic.update(traces: logistic_traces)
              else
                raise result.dig("msg") || "同步AE订单跟踪信息失败"
              end
            end
          end
        rescue => e
          retry_times -= 1
          retry if retry_times.positive?
        end
      end
    end

    def deliver_order_refund(refund_params)
      refund_amount_in_cent = (refund_params[:refund_amount_in_yuan].to_f * 100).round
      can_refund_amount = completed_charge_payment.can_refund_amount(true, true, true, true)
      if refund_amount_in_cent > can_refund_amount
        self.errors.add(:base, I18n.t("error.order.refund_amount_exceeds_can_refund_amount", can_refund_amount: can_refund_amount / 100.0))
        return false
      else
        @refund_amount_in_cent = refund_amount_in_cent
        perform_aasm_event(:refund)
      end
    end

    def enqueue_refund_job_with_amount
      # 从实例变量中获取退款金额，如果没有设置则使用默认值
      refund_amount = @refund_amount_in_cent
      enqueue_refund_job(refund_amount)
    end

    private

    def wait_buyer_pay_order_max_count
      if user.orders.wait_buyer_pay.size >= MAX_WAIT_BUYER_PAY_COUNT
        self.errors.add(:base, I18n.t("error.order.too_many_pending_orders"))
      end
    end

    def check_buy_quota
      order_items.each do |order_item|
        next if order_item.item.buy_quota.to_i.zero?

        bought_quantity = if order_item.item.buy_quota_days.zero?
                            MagicBean::OrderItem.where(order: user.orders.effective)
                          else
                            current_time = Time.current
                            MagicBean::OrderItem.where(order: user.orders.effective.where(created_at: (current_time - order_item.item.buy_quota_days.days)..current_time))
                          end.where(item: order_item.item).sum(:quantity)

        next if bought_quantity + order_item.quantity <= order_item.item.buy_quota

        errors[:base] << I18n.t("error.order.purchase_limit", sku_title: order_item.item.title)

      end
    end

    def generate_order_no
      no_prefix = Rails.env.production? ? "" : "S"
      loop do
        self.no = no_prefix + Time.now.strftime("%Y%m%d%H%M%L") + rand.to_s[2..4]
        break unless self.class.exists?(no: no)
      end
    end

    def regenerate_order_no
      generate_order_no
      self.save
    end

    def generate_refund_no
      no_prefix = Rails.env.production? ? "" : "S"
      loop do
        self.refund_no = no_prefix + Time.now.strftime("%Y%m%d%H%M%L") + rand.to_s[2..4]
        break unless self.class.exists?(refund_no: refund_no)
      end
    end

    def enqueue_close_order_job
      CloseOrderJob.set(wait_until: latest_payment_time).perform_later(id)
    end

    def enqueue_push_order_wait_for_pay_job
      PushOrderWaitForPaidJob.set(wait_until: (latest_payment_time - 5.minutes)).perform_later(id)
    end

    def enqueue_notify_risk_order_result_job
      message = trade_closed? ? "您的订单 #{no}，存在交易风险，请联系eBest客服" : "您的订单 #{no}，付款已确认"

      MagicBean::AppNotifier.enqueue_app_push_job("订单支付审核", message, user_id, { app_link: { type: "order", params: { id: id } }.to_json })
    end

    def remove_shopping_cart_items
      return if is_direct_buy
      user.shopping_cart_items
        .where(
          stock_keeping_unit_id: order_items.map(&:stock_keeping_unit_id)
        ).destroy_all
      user.reset_redis_store_shopping_cart_items
    end

    def set_default_value
      return unless self.new_record?
      self.authority_to_leave = false if self.authority_to_leave.blank?
      if self.deliver_to_door.blank? || !merchant_delivery?
        self.deliver_to_door = false
        self.deliver_to_door_service_fee_in_cent = 0
      end
      self.quantity = order_items.to_a.pluck(:quantity).sum
      self.integral_deducted_from_one_yuan = default_site_config&.integral_deducted_from_one_yuan
      self.order_finished_reward_integral = default_site_config&.order_finished_reward_integral
    end

    def set_default_delivery_type
      return if !self.new_record? || !is_preview || delivery_type
      self.delivery_type = (["merchant_delivery", "self_pick", "express", "virtual_delivery"] & items_available_delivery_types).first
    end

    def update_prepay_id(prepay_id, ebest_channel)
      update_columns(prepay_id: prepay_id, channel: ebest_channel)
    end

    # 下单减少库存
    def decrease_inventory!
      inventory_errors_count = 0

      order_items.order(:stock_keeping_unit_id).each do |order_item|
        sku_title = order_item&.sku_human_title
        # 用显式事务，不然后续的任何数据库查询都会报错
        ActiveRecord::Base.transaction(requires_new: true) do
          begin
            order_item&.decrease_inventory!
          rescue => _
            inventory_errors_count += 1
            errors[:base] << " #{sku_title} #{I18n.t("grape.orders.insufficient_inventory")} "
            # 内部事务要及时回滚
            raise ActiveRecord::Rollback
          end
        end
      end

      # 这里需要拿gifts的实时库存，不拿gifts方法
      gifts_properties.to_a.each do |gift|
        gift_sku = MagicBean::StockKeepingUnit.find_by(id: gift["stock_keeping_unit_id"])
        # 如果decrease_inventory报错，在rescue中获取human_title会报错: current transaction is aborted, commands ignored until end of transaction block
        sku_title = gift_sku&.human_title
        ActiveRecord::Base.transaction(requires_new: true) do
          begin
            gift_sku&.decrease_inventory!(gift["quantity"])
          rescue => _
            inventory_errors_count += 1
            errors[:base] << I18n.t("error.order.gift_out_of_stock", sku_title: sku_title)
            raise ActiveRecord::Rollback
          end
        end       
      end

      raise ActiveRecord::RecordInvalid if inventory_errors_count > 0

      errors_count = 0
      valid_pool_gifts_properties = pool_gifts_properties

      sku_messages = {}

      (pool_gifts_properties || []).each do |pool_gift|
        sku_messages[pool_gift["notification_emails"]] ||= { less_than_messages: [], out_of_stock_messages: [] }

        ActiveRecord::Base.transaction(requires_new: true) do
          begin
            sku = MagicBean::StockKeepingUnit.find_by(id: pool_gift["stock_keeping_unit_id"])
            if sku
              sku_title = sku.human_title
              sku.decrease_inventory!(pool_gift["quantity"])
              # 仅数量等于预警数量才发邮件
              sku_messages[pool_gift["notification_emails"]][:less_than_messages] << "#{sku_title}库存为#{sku.quantity}" if sku.quantity <= pool_gift["notification_quantity"]
            end
          rescue => _
            valid_pool_gifts_properties -= [pool_gift]
            errors_count +=1
            sku_messages[pool_gift["notification_emails"]][:out_of_stock_messages] << "赠品 #{sku_title} 库存不足！"
            raise ActiveRecord::Rollback
          end
        end
      end

      sku_messages.keys.each do |emails|
        target_messages = sku_messages[emails]
        OrderMailer.with(order_id: id, sku_messages: sku_messages[emails], emails: emails.split(/[;；]/)).sku_notify.deliver_later if emails.present? && (target_messages[:less_than_messages].present? || target_messages[:out_of_stock_messages].present?)
      end

      # 库存不足的赠品要从赠品目录移除
      update_columns(pool_gifts_properties: valid_pool_gifts_properties) if errors_count.positive?
    end

    # 订单关闭恢复库存，缺货的不恢复
    def increase_inventory!
      # 整单缺货不回退库存
      return if stockout?

      log_messages = []
      order_items.order(:stock_keeping_unit_id).each do |order_item|
        can_not_increase_quantity = order_item.wms_refunded_after_sales_order_items.sum(:quantity)
        # 如果是全部缺货就无须退库存
        next if order_item.quantity <= can_not_increase_quantity
        old_quantity = order_item.stock_keeping_unit.quantity
        increase_quantity = order_item.quantity - can_not_increase_quantity
        order_item.increase_inventory!(increase_quantity)
        # 由于担心库存增加后有别的订单减了库存，所以记录到日志的最新库存用old_quantity + increase_quantity来计算
        log_messages << "SKU: #{order_item.stock_keeping_unit.no} 库存由#{old_quantity}变为#{old_quantity + increase_quantity}"
      end

      gifts.each do |gift|
        old_quantity = gift[:sku].quantity
        gift[:sku]&.increase_inventory!(gift[:quantity])
        log_messages << "SKU: #{gift[:sku].no} 库存由#{old_quantity}变为#{old_quantity + gift[:quantity]}"
      end if gifts.present?

      pool_gifts.each do |gift|
        old_quantity = gift[:sku].quantity
        gift[:sku]&.increase_inventory!(gift[:quantity])
        log_messages << "SKU: #{gift[:sku].no} 库存由#{old_quantity}变为#{old_quantity + gift[:quantity]}"
      end if pool_gifts.present?

      if log_messages.present?
        MagicBean::OperationRecord.create(operatable: self, content: log_messages.join(", "), store_id: store_id, channel: "admin")
      end
    end

    # 支付订单后更新统计数据
    def update_statistical_data
      increase_valid_orders_count!
    end

    # 下单增加产品销售量
    def increase_sales_count!
      order_items.map(&:increase_sales_count!)
    end

    # 订单关闭减少产品销售量
    def decrease_sales_count!
      order_items.map(&:decrease_sales_count!)
    end

    def increase_valid_orders_count!
      user.increment!(:valid_orders_count)
    end

    def update_finished_at
      update_columns(finished_at: Time.current)
    end

    def update_confirmed_at
      update_columns(confirmed_at: Time.current)
    end

    def update_delivered_at
      update_columns(delivered_at: Time.current)
    end

    def send_drawback_wechat_template_message
      SendSubscribeMessagesJob.perform_later(template_message_params("refund"))
    end

    def send_deliver_wechat_template_message
      SendSubscribeMessagesJob.perform_later(template_message_params("delivery"))
    end

    def send_apply_refund_email_to_admin_users
      OrderMailer.with(order: self).apply_refund.deliver_later
    end

    # 纪录支付时间的同时纪录当下获得积分比例
    def set_paid_at
      unless paid_at?
        self.paid_at = Time.current
        self.integral_received_from_one_yuan = calculate_integral_received_from_one_yuan
        self.save
      end
    end

    def enqueue_confirm_goods_job
      ConfirmOrderJob.set(wait_until: (ae_drop_shipper ? AE_CONFIRM_GOODS_TIME : CONFIRM_GOODS_TIME).from_now).perform_later(id)
    end

    def enqueue_finish_order_job
      FinishOrderJob.set(wait_until: FINISH_ORDER_TIME.from_now).perform_later(id)
    end

    def enqueue_refinish_order_job
      RefinishOrderJob.set(wait_until: FINISH_ORDER_TIME.from_now).perform_later(id)
    end

    def set_coupon_used
      coupon.update(status: :used, used_at: Time.current) if coupon
    end

    def set_gift_card_coupon_used_amount
      if gift_card_coupon
        gift_card_coupon.with_lock do
          gift_card_coupon.increment!(:used_amount_in_cent, gift_card_amount_in_cent)
          
          if gift_card_coupon.used_amount_in_cent > gift_card_coupon.denominations_in_cent
            errors[:base] << I18n.t("grape.orders.gift_card_insufficient_blance")
            raise ActiveRecord::RecordInvalid
          elsif gift_card_coupon.used_amount_in_cent == gift_card_coupon.denominations_in_cent
            gift_card_coupon.update_columns status: :used
          end
        end
      end
    end

    # 整单申请退款、直接退款的情况返还优惠券
    def release_coupon
      coupon.update(status: :pending, used_at: nil) if aasm(:status).from_state.in?([:wait_buyer_pay, :refunding]) && coupon && coupon.used?
    end

    def release_promo_code
      if aasm(:status).from_state.eql?(:wait_buyer_pay)
        promo_code&.decrement!(:used_count)
      end
    end

    def release_gift_card_coupon
      if gift_card_coupon
        gift_card_coupon.with_lock do
          gift_card_coupon.decrement!(:used_amount_in_cent, gift_card_amount_in_cent)
          gift_card_coupon.update_columns status: :pending
        end
      end
    end

    def update_new_user_to_false
      user.update_columns(new_user: false) if user.new_user?
    end

    # 拼团订单重写该方法，用于创建或完成拼团活动
    def additional_pay_success_callbacks
    end

    # 拼团订单重写该方法，用于关闭拼团活动
    def additional_close_success_callbacks
    end

    def update_is_sent_but_status_not_show_to_false
      update_columns(is_sent_but_status_not_show: false) if is_sent_but_status_not_show
    end

    def can_show_fake_deliver?
      %w[development staging].include?(Rails.env) && refundable?
    end

    def payment_in_cent_eql_zero?
      payment_in_cent == 0
    end

    def pay_order
      self.pay!
    end

    def check_delivery_type
      # item's delivery_type is an array
      items_delivery_types = MagicBean::Item.where(id: order_items.map(&:item_id)).pluck(:delivery_type)
      if items_delivery_types.detect { |delivery_type| (delivery_type & [self.delivery_type]).blank? }
        errors.add(:base, I18n.t("error.order.different_delivery_types"))
      end
    end

    def current_delivery_area
      @current_delivery_area ||= MagicBean::DeliveryArea.ransack(
        postal_code_eq: receiver_postal_code&.strip || -1,
        suburb_case_insensitive_eq: receiver_city_name&.strip&.downcase || -1
      ).result.first
    end

    def check_merchant_delivery_address
      errors.add(:base, I18n.t("error.order.not_supported_merchant_delivery_address")) if receiver_properties.present? && current_delivery_area&.au_suburb&.store_id != store_id
    end

    def check_delivery_time
      errors.add(:base, I18n.t("error.order.delivery_time_presence")) if !is_preview && (delivery_date.blank? || prefer_time.blank?)
      return if available_delivery_time.nil?
      
      if delivery_date.blank? && prefer_time.blank? && (merchant_delivery? || (self_pick? && self_pick_up.present?))
        # 由于商家配送时间段有额外运费，所以不默认选择
        if self_pick?
          self.prefer_time = available_delivery_time.time_period.first
        end

        self.delivery_date = available_delivery_dates.first[:date] if available_delivery_dates.present?
      end

      if merchant_delivery?
        self.mark_for_orders_limit = available_delivery_time.limited_by_orders_limit_every_day
        self.delivery_time_id = available_delivery_time&.id
        self.prefer_time = delivery_time_period_setting.prefer_time if delivery_time_period_setting_id.present?
      end

      if !is_preview && (!delivery_date.to_date.wday.to_s.in?(available_delivery_time.weekdays) || (self_pick? && !prefer_time.in?(available_delivery_time.time_period)))
        if merchant_delivery?
          errors.add(:base, I18n.t("error.order.time_not_support_merchant_delivery"))
        else
          errors.add(:base, I18n.t("error.order.time_not_support_self_pickup"))
        end
      end
    end

    # Item A
    # dispatch time 周六 10 - 12
    # Item B
    # dispatch time 周日 10 - 12
    # Item C
    # dispatch time 周日 11 - 16
    # 在配送范围内 （周日 9-21；21-23）
    # 使用 dispatch time 周日 11 - 16 去匹配
    # order 的 delivery time 周日 9-21
    # 不在配送范围内
    # 直接使用 dispatch time 周日 11 - 16
    def calculate_earliest_delivery_time
      return [@earliest_delivery_time, @available_presell_dispatch_date, @conflicted_items] if @earliest_delivery_time.present?
      current_time = Time.current
      # 计算商品配送时间中的最晚一个，作为order的最早可配送时间
      earliest_delivery_times = order_items.map(&:item).map do |item|
        d_time = if merchant_delivery?
                   item.calculate_earliest_delivery_time(current_time, user_postal_code, user_suburb)
                 elsif self_pick?
                   item.calculate_earliest_delivery_time(current_time, nil, nil, self_pick_up_id)
                 else
                   item.calculate_earliest_dispatch_time(current_time, current_store_site_config)
                 end
        next if d_time.blank?
        d_time[:title] = item.title
        d_time[:presell_dispatch_date] = item.presell_dispatch_on
        d_time
      end.compact

      # 获取最早的预售配送结束日期
      presell_delivery_times = earliest_delivery_times.select {|t| t[:latest_presell_dispatch_date].present? }
      @available_presell_dispatch_date = presell_delivery_times.map {|time| time[:latest_presell_dispatch_date]}.sort.first
      @earliest_delivery_time = earliest_delivery_times.sort { |t1, t2| "#{t2[:date]} #{t2[:time].split("-")[0]}".in_time_zone <=> "#{t1[:date]} #{t1[:time].split("-")[0]}".in_time_zone }.first
      # 获取时间冲突商品
      @conflicted_items = presell_delivery_times.map do |t|
        "#{t[:title]}，可派送日期为#{t[:presell_dispatch_date]} ~ #{t[:latest_presell_dispatch_date]}" if t[:latest_presell_dispatch_date] < @earliest_delivery_time[:date]
      end.compact

      [@earliest_delivery_time, @available_presell_dispatch_date, @conflicted_items]
    end

    # FIXME: 现在配送地址数满了就不会把日期写入available_delivery_dates，希望子单还是可以选中配送日期，但影响较小，先不处理
    def available_delivery_dates
      return @available_delivery_dates if @available_delivery_dates.present?
      return [] if available_delivery_time.nil?
      earliest_delivery_time, available_presell_dispatch_date, conflicted_items = calculate_earliest_delivery_time

      return [] if earliest_delivery_time.blank?
      # 如果包含预售商品，计算配送日期是否早于预售结束日期
      if available_presell_dispatch_date.present? && earliest_delivery_time[:date] > available_presell_dispatch_date
        errors.add(:base, I18n.t("error.order.conflicted_items", item_titles: conflicted_items.join("; "))) if conflicted_items.present? && order_items.size > 1
        return []
      end

      available_date = earliest_delivery_time[:date]
      @available_delivery_dates = []

      # 特殊需求: 关闭卧龙岗几个配送时间管理9月16日-9月24日的配送日期
      tmp_not_delivery_dates = MagicBean::Item::NOT_DELIVERY_DAYS

      # if (merchant_delivery? && available_delivery_time.id.in?([11, 22, 23])) || (self_pick? && available_delivery_time.id.in?([11]))
      #   tmp_not_delivery_dates = (tmp_not_delivery_dates + ("2022-09-16".."2022-09-24").to_a).uniq
      # end

      weekdays_conflicted_items = []
      all_delivery_weeks = []
      order_items.each do |order_item|
        item_weekdays = order_item.item.delivery_weekdays
        next if item_weekdays.blank?

        weekdays_conflicted_items << order_item.item.title

        all_delivery_weeks << item_weekdays
      end

      order_items_delivery_weeks = all_delivery_weeks.inject { |week1, week2| week1 & week2 }

      # 如果存在设置了配送星期数，但多个商品配送日期没有重合星期数时，则提示商品时间冲突
      if weekdays_conflicted_items.present? && order_items_delivery_weeks.blank?
        errors.add(:base, I18n.t("error.order.conflicted_items", item_titles: weekdays_conflicted_items.join("; ")))
        return []
      end

      available_weekdays = order_items_delivery_weeks.present? ? (available_delivery_time.weekdays & order_items_delivery_weeks) : available_delivery_time.weekdays
      if merchant_delivery?
        has_no_limit_setting = available_delivery_time.delivery_time_period_settings.where(order_address_limit_every_day: 0).exists?
        total_address_limit = available_delivery_time.delivery_time_period_settings.sum(:order_address_limit_every_day)
        time_periods_hash = {}
        # 如果是由全站配置的地址数控制，则把地址数限制设置为0
        available_delivery_time.delivery_time_periods.includes(:translations, :delivery_time_period_settings).each do |delivery_time_period|
          time_periods_hash[delivery_time_period.title] = delivery_time_period.delivery_time_period_settings.map {|setting| {
            id: setting.id,
            prefer_time: setting.prefer_time,
            order_address_limit_every_day: available_delivery_time.limited_by_orders_limit_every_day ? 0 : setting.order_address_limit_every_day,
            address_limit_left: 0,
            freight_in_yuan: setting.freight_in_yuan,
          }}
        end
      end

      loop do
        # 布里斯班2023-07-01之后的日期不可选
        # 2024-01-26是澳洲国庆，2000邮编的自派订单均不配送
        unless available_date.to_s.in?(tmp_not_delivery_dates) || (store_id == 4 && available_date.to_s >= "2023-07-01") || (store_id == 3 && available_date.to_s >= "2023-08-20") || (merchant_delivery? && available_date.to_s == "2024-01-26" && user_postal_code.to_s == "2000")
          if available_date.wday.to_s.in?(available_weekdays)
            if merchant_delivery?
              custom_merchant_address_limit = merchant_delivery_address_limit

              if available_delivery_time.limited_by_orders_limit_every_day
                if custom_merchant_address_limit.zero?
                  @available_delivery_dates << { date: available_date, wday: wday_display(available_date), time_periods: time_periods_hash }
                else
                  distinct_address_count = merchant_distinct_address_count(available_date)

                  if custom_merchant_address_limit.zero? || distinct_address_count < custom_merchant_address_limit
                    @available_delivery_dates << { date: available_date, wday: wday_display(available_date), time_periods: time_periods_hash }
                  end
                end
              else
                distinct_address_count = delivery_time_distinct_address_count(available_date)

                if has_no_limit_setting || total_address_limit > distinct_address_count
                  # 计算每个时间段的配送剩余量
                  # 创建time_periods_hash的深拷贝，避免修改同一个对象引用
                  time_periods_hash_copy = Marshal.load(Marshal.dump(time_periods_hash))
                  
                  time_periods_hash_copy.keys.each do |period_title|
                    time_periods_hash_copy[period_title].each do |time_period_setting|
                      next if time_period_setting[:order_address_limit_every_day].zero?
                      used_address_count = delivery_time_period_distinct_address_count(available_date, time_period_setting[:id])
                      time_period_setting[:address_limit_left] = time_period_setting[:order_address_limit_every_day] - used_address_count
                    end
                  end

                  @available_delivery_dates << { date: available_date, wday: wday_display(available_date), time_periods: time_periods_hash_copy }
                end
              end
            elsif self_pick?
              if self_pick_orders_limit.positive?
                orders_count = self_pick_date_orders_count(available_date)
                @available_delivery_dates << { date: available_date, wday: wday_display(available_date) } if self_pick_orders_limit > orders_count
              else
                @available_delivery_dates << { date: available_date, wday: wday_display(available_date) }
              end
            end
          end
        end

        available_date += 1.day

        break if available_presell_dispatch_date.present? && available_date > available_presell_dispatch_date # 超过预售结束日期的日期不再计算

        break if (earliest_delivery_time[:date] + MAX_DELIVERY_DAY.days) < available_date # 只计算到未来7天
      end

      @available_delivery_dates
    end

    def wday_display(date)
      date == Date.tomorrow ? I18n.t("grape.delivery.tomorrow") : I18n.l(date, format: "%a")
    end

    def user_postal_code
      receiver_postal_code || current_postal_code
    end

    def user_suburb
      receiver_city_name || current_suburb
    end

    def check_receiver_values
      if receiver_first_name.blank? || receiver_last_name.blank? || receiver_tel_number.blank?
        errors.add(:base, I18n.t("error.order.receiver_values_presence"))
      else
        errors.add(:base, I18n.t("error.mobile.invalid_format")) unless Phony.plausible?(receiver_tel_number)
      end
    end

    def auto_apply_refund
      if refundable? && may_apply? && apply!
        auto_refund_remark = I18n.t("error.order.out_of_stock_and_refund", locale: user.locale)
        update(remark: auto_refund_remark)
      end
    end

    def update_sync_status_after_refuse
      confirmed! if stockout?
    end

    def check_user_is_blocked
      errors.add(:base, I18n.t("error.order.fraud_account")) if user.is_blocked?
    end

    def receiver_tel_number_not_in_blacklist
      return if receiver_tel_number.blank?

      if MagicBean::MobileBlacklist.activated?(receiver_tel_number, :order_disabled)
        errors.add(:base, I18n.t("error.order.fraud_account"))
      end
    end

    def delete_order_item_which_quantity_was_zero
      return unless self.new_record?
      self.order_items = order_items.select { |oi| oi.quantity > 0 }
    end

    def has_item_cutoff_time?
      items.any? { |item| item.cutoff_times.present? }
    end

    def generate_and_assign_gift_coupon_to_user
      return if gift_coupon_template.blank?

      gift_coupon_template.generate_coupon_and_assign_with_notification(user_id)
    end

    def generate_and_assign_pool_gift_coupons_to_user
      return if pool_coupon_template_ids.blank?

      transaction do
        MagicBean::CouponTemplate.where(id: pool_coupon_template_ids).each do |template|
          assign_times = pool_coupon_template_ids.length - (pool_coupon_template_ids - [template.id]).length

          assign_times.times.each do
            template.generate_coupon_and_assign_with_notification(user_id)
          end
        end
      end
    end

    def current_store_site_config
      @current_store_site_config ||= store.site_config
    end

    def current_store_deliver_to_door_service_fee
      (current_store_site_config.deliver_to_door_service_fee.to_f * 100).round
    end

    def current_store_cutoff_time_string
      # 动态获取当前store配置的cutoff_time, 获取比较大的时间
      format_cutoff_time = current_store_site_config.format_cutoff_time.last
      format_cutoff_time.present? ? format_cutoff_time[:time] : CUTOFF_TIME
    end

    def integral_special_period_rule
      @integral_special_period_rule ||= current_store_site_config.integral_special_period_rule
    end

    def merchant_delivery_address_limit
      @merchant_delivery_address_limit ||= Rails.cache.redis.get("store-#{store_id}-orders-limit-every-day").to_i
    end

    def self_pick_orders_limit
      self_pick_up&.self_pick_orders_limit_every_day.to_i.abs
    end

    # 后台修改delivery_date后需要重新计算这两天的配送量
    def reset_order_date_analysis
      return if virtual_delivery? || express? || previous_changes["delivery_date"].blank? || trade_closed?
      set_order_date_analysis_to_redis(previous_changes["delivery_date"][0], -1)
      set_order_date_analysis_to_redis(previous_changes["delivery_date"][1])
    end

    def set_order_date_analysis_to_redis(new_delivery_date, add_count = 1)
      if merchant_delivery?
        if mark_for_orders_limit
          redis_key = merchant_order_limit_redis_key(new_delivery_date)
          count = Rails.cache.redis.hincrby redis_key, receiver_properties.to_json, add_count
          Rails.cache.redis.hdel redis_key, receiver_properties.to_json unless count.positive?
          recalculate_merchant_orders_data(new_delivery_date)
        end

        delivery_time_count = Rails.cache.redis.hincrby delivery_time_order_limit_redis_key(new_delivery_date), receiver_properties.to_json, add_count
        Rails.cache.redis.hdel delivery_time_order_limit_redis_key(new_delivery_date), receiver_properties.to_json unless delivery_time_count.positive?
        recalculate_delivery_time_orders_data(new_delivery_date)
      elsif self_pick?
        self_pick_count = Rails.cache.redis.incrby self_pick_order_limit_redis_key(new_delivery_date), add_count
        Rails.cache.redis.del self_pick_order_limit_redis_key(new_delivery_date) unless self_pick_count.positive?
      end
    end

    # 用户在订单结束后才支付的订单处理
    # 主要: 调用该方法请在事务中执行
    # TODO: 这里要兼容待审核状态
    def pay_when_order_closed
      if live_top
        update_columns(status: :live_top_confirm)
      else
        update_columns(status: :wait_seller_send_goods)
      end

      return_integral_records = integral_records.spent_return
      if return_integral_records.present?
        cost_integral = return_integral_records.sum(:integral)
        channel_prefix = return_integral_records.first.send :channel_prefix
        member = user_member
        member.decrement!("#{channel_prefix}available_integral", cost_integral)
        return_integral_records.destroy_all
      end

      set_gift_card_coupon_used_amount
      set_coupon_used
      promo_code&.increment!(:used_count)

      # 这里要跳过减库存失败的错误
      order_items.order(:stock_keeping_unit_id).each do |item|
        begin
          item&.decrease_inventory!
        rescue => _
        end
      end

      gifts.each do |gift|
        begin
          gift[:sku]&.decrease_inventory!(gift[:quantity])
        rescue => _
        end
      end if gifts.present?

      pool_gifts.each do |gift|
        begin
          gift[:sku]&.decrease_inventory!(gift[:quantity])
        rescue => _
        end
      end if pool_gifts.present?

      increase_sales_count!

      after_paid_actions
      additional_pay_success_callbacks
      send_order_paid_notice
      counter_to_redis
    end

    def risk_pay_when_order_closed
      update_columns(status: :risk_pay)

      return_integral_records = integral_records.spent_return
      if return_integral_records.present?
        cost_integral = return_integral_records.sum(:integral)
        channel_prefix = return_integral_records.first.send :channel_prefix
        member = user_member
        member.decrement!("#{channel_prefix}available_integral", cost_integral)
        return_integral_records.destroy_all
      end

      set_gift_card_coupon_used_amount
      set_coupon_used
      promo_code&.increment!(:used_count)

      # 这里要跳过减库存失败的错误
      order_items.order(:stock_keeping_unit_id).each do |item|
        begin
          item&.decrease_inventory!
        rescue => _
        end
      end

      gifts.each do |gift|
        begin
          gift[:sku]&.decrease_inventory!(gift[:quantity])
        rescue => _
        end
      end if gifts.present?

      pool_gifts.each do |gift|
        begin
          gift[:sku]&.decrease_inventory!(gift[:quantity])
        rescue => _
        end
      end if pool_gifts.present?

      increase_sales_count!

      counter_to_redis
    end

    def merchant_distinct_address_count(delivery_date)
      Rails.cache.redis.get(merchant_addresses_count_redis_key(delivery_date)).to_i
    end

    def delivery_time_distinct_address_count(delivery_date)
      Rails.cache.redis.get(delivery_time_addresses_count_redis_key(delivery_date)).to_i
    end

    def delivery_time_period_distinct_address_count(delivery_date, period_id)
      Rails.cache.redis.get(delivery_time_period_addresses_count_redis_key(delivery_date, period_id)).to_i
    end

    def self_pick_date_orders_count(delivery_date)
      Rails.cache.redis.get(self_pick_order_limit_redis_key(delivery_date)).to_i
    end

    def merchant_order_limit_redis_key(new_delivery_date = nil)
      MERCHANT_ORDER_LIMIT_REDIS_KEY % { store_id: store_id, delivery_date: new_delivery_date || delivery_date }
    end

    def merchant_addresses_count_redis_key(new_delivery_date = nil)
      MERCHANT_ADDRESSES_COUNT % { store_id: store_id, delivery_date: new_delivery_date || delivery_date }
    end

    def delivery_time_order_limit_redis_key(new_delivery_date = nil, period_id = nil)
      DELIVERY_TIME_ORDER_LIMIT_REDIS_KEY % { delivery_time_id: delivery_time_id || available_delivery_time&.id, delivery_date: new_delivery_date || delivery_date, period_id: period_id || delivery_time_period_setting_id }
    end

    def delivery_time_addresses_count_redis_key(new_delivery_date = nil)
      DELIVERY_TIME_ADDRESSES_COUNT % { delivery_time_id: delivery_time_id || available_delivery_time&.id, delivery_date: new_delivery_date || delivery_date }
    end

    def delivery_time_period_addresses_count_redis_key(new_delivery_date = nil, period_id = nil)
      DELIVERY_TIME_ADDRESSES_COUNT_WITH_PERIOD % { delivery_time_id: delivery_time_id || available_delivery_time&.id, delivery_date: new_delivery_date || delivery_date, period_id: period_id || delivery_time_period_setting_id }
    end

    def self_pick_order_limit_redis_key(new_delivery_date = nil)
      SELF_PICK_ORDER_LIMIT_REDIS_KEY % { self_pick_up_id: self_pick_up_id, delivery_date: new_delivery_date || delivery_date }
    end

    def counter_to_redis
      return if delivery_date.blank? || express?

      if self_pick?
        Rails.cache.redis.incrby self_pick_order_limit_redis_key, 1
      elsif merchant_delivery? && receiver_properties.present?
        if available_delivery_time&.limited_by_orders_limit_every_day
          Rails.cache.redis.hincrby(merchant_order_limit_redis_key, receiver_properties.to_json, 1)
          recalculate_merchant_orders_data
        end

        Rails.cache.redis.hincrby delivery_time_order_limit_redis_key, receiver_properties.to_json, 1
        recalculate_delivery_time_orders_data
      end
    end

    def release_counter_from_redis
      return if delivery_date.blank? || express?

      if self_pick?
        # 自减自提订单上限统计
        self_pick_count = Rails.cache.redis.incrby self_pick_order_limit_redis_key, -1
        Rails.cache.redis.del self_pick_order_limit_redis_key unless self_pick_count.positive?
      elsif merchant_delivery? && receiver_properties.present?
        if available_delivery_time&.limited_by_orders_limit_every_day
          # 自减自派订单上限统计
          redis_key = merchant_order_limit_redis_key
          count = Rails.cache.redis.hincrby redis_key, receiver_properties.to_json, -1
          Rails.cache.redis.hdel redis_key, receiver_properties.to_json unless count.positive?
          recalculate_merchant_orders_data
        end

        # 自减区域特定订单上限统计
        delivery_time_count = Rails.cache.redis.hincrby delivery_time_order_limit_redis_key, receiver_properties.to_json, -1
        Rails.cache.redis.hdel delivery_time_order_limit_redis_key, receiver_properties.to_json unless delivery_time_count.positive?
        recalculate_delivery_time_orders_data
      end
    end

    def recalculate_merchant_orders_data(new_delivery_date = nil)
      merchant_order_limit = Rails.cache.redis.hgetall(merchant_order_limit_redis_key(new_delivery_date))
      addresses_count = merchant_order_limit.keys.count
      Rails.cache.redis.set merchant_addresses_count_redis_key(new_delivery_date), addresses_count
    end

    def recalculate_delivery_time_orders_data(new_delivery_date = nil)
      # hgetall不支持通配符，需要先把时间段下的key都获取出来, 用于计算当天所有时间段的地址数
      delivery_time_order_limit_keys = Rails.cache.redis.keys(delivery_time_order_limit_redis_key(new_delivery_date, "*"))

      addresses_count, orders_count, period_addresses_count = 0, 0, 0

      delivery_time_order_limit_keys.each do |key|
        delivery_time_order_limit = Rails.cache.redis.hgetall(key)
        tmp_addresses_count = delivery_time_order_limit.keys.count
        addresses_count += tmp_addresses_count
        orders_count += delivery_time_order_limit.values.map(&:to_i).sum
        period_addresses_count = tmp_addresses_count if key == delivery_time_order_limit_redis_key(new_delivery_date)
      end

      Rails.cache.redis.set delivery_time_addresses_count_redis_key(new_delivery_date), addresses_count
      Rails.cache.redis.set delivery_time_period_addresses_count_redis_key(new_delivery_date), period_addresses_count
    end

    # 被邀请人下的第一单完成后发券给邀请人
    def reward_inviter
      inviter = user_member.inviter
      inviter.send(:assign_finish_order_coupon_to_inviter, user_member.id) if inviter && user.orders.trade_finished.where.not(id: id).blank?
    end

    def self.can_use_free_shipping_code?(channel, user, tmp_time_zone)
      # 在07-01之前可以使用免运费码
      Time.current < "2023-07-01".in_time_zone(tmp_time_zone) && channel == 'web' && user.new_user && user.orders.where.not(status: :trade_closed).blank?
    end

    def try_set_express_carrier
      self.express_carrier = KUAIMA_COMPANY if satisfy_kuaima_delivery?
    end

    # 满足以下条件才会设置快马配送
    # 1. 允许放在门口
    # 2. 不送货上楼
    # 3. 商品（包括赠品）皆为常温存储
    # 4. 配送类型为 merchant_delivery
    # 5. 订单 channel 为 app 或小程序
    # 6. 邮编在快马配送区域内 KUAIMA_DELIVERY_POST_CODES
    # 7. 下单没有备注留言
    def satisfy_kuaima_delivery?
      type != "MagicBean::SameDayDeliveryOrder" && buyer_message.blank? && channel.in?(["app", "mini_program"]) && merchant_delivery? && authority_to_leave && !deliver_to_door && postcode_in_kuaima_delivery_area? && all_items_are_room_temp_storage?
    end

    def postcode_in_kuaima_delivery_area?
      KUAIMA_DELIVERY_POST_CODES.include?(receiver_postal_code)
    end

    def all_items_are_room_temp_storage?
      item_ids = order_items_with_gifts.map(&:item_id)
      MagicBean::Item.where(id: item_ids).pluck(:storage_method).all? { |storage_method| storage_method == "room_temp_storage" }
    end

    def build_kuaima_delivery_track_url(track_number)
      # 快马只有一个正式环境的物流查询地址
      "https://fh.express/search?orderNo=#{track_number}"
    end

    # 如果母单直接退款，先判断是否有其他母单，如果有其他母单，不做任务操作
    # 如果没其他母单，子单全部退款
    def refund_child_orders
      # 子单退款或直播待确认订单不做处理
      return if is_child || live_top
      return if has_other_parent_orders?

      child_orders.each do |child_order|
        # 如果子弹是风险支付，直接关闭
        if child_order.risk_pay?
          child_order.close!
        else
          child_order.refund! if child_order.refundable?
        end       
      end
    end

    # 子单不可使用优惠券和金币
    def child_order_cannot_user_coupon_and_integral
      if is_child
        self.errors.add(:base, I18n.t("error.order.child_order_cannot_use_coupon")) if coupon 
        self.errors.add(:base, I18n.t("error.order.child_order_cannot_use_integral")) if cost_integral.positive?
      end
    end

    def exchange_integral_to_aus_dollar(integral)
      (integral.to_f * 100 / integral_deducted_from_one_yuan).round
    end

    # 检查邮寄订单是否超重，超过20kg不允许下单
    def check_order_is_overweight
      # 跨境购不需要确认重量
      return if order_items.blank? || !express? || ae_drop_shipper
      # 单位: 克
      total_weight_in_gram = order_items.sum { |item| item.weight_in_gram * item.quantity }

      self.errors.add(:base, I18n.t("error.order.overweight")) if total_weight_in_gram > MAX_ORDER_WEIGHT
    end

    def sync_to_aliexpress
      return unless ae_drop_shipper
      retry_times = 2
      begin
        # 调用aliexpress的接口同步订单
        # 成功：{"result"=>{"is_success"=>true, "order_list"=>[1108798924344059]}, "request_id"=>"2101231a17310636890088841"}
        # 失败：{"result"=>{"error_code"=>"DELIVERY_METHOD_NOT_EXIST", "is_success"=>false}, "request_id"=>"21411c3d17310623891123639"}
        # 现在每个SKU会生成一个AE订单号，order_list会有多数据
        response = Aliexpress::Api.create_ds_order(self).body
        if response["result"]["is_success"]
          update_columns(ae_order_list: response["result"]["order_list"])

          # 立刻触发同步，后面每1小时同步一次订单状态
          SyncAeOrderStatusJob.perform_later(id)
        else
          update_columns(ae_error_response: response, remark: I18n.t("error.order.ae_out_of_stock_and_refund", locale: user.locale))

          # 给用户发客服通知
          create_ae_order_failed_and_refund_app_text_message

          # 目前选品会库存多的商品，订单包含库存不足的商品会同步失败，目前ebest采用的方案是先直接退款
          # 十分钟后再触发退款，避免影响app交互
          RefundOrderJob.set(wait: 10.minutes).perform_later(id)

          # 对该订单的产品触发更新上架状态
          order_items.each do |item|
            CheckAeItemsDeliveryStatusJob.perform_later(item.item_id)
          end
        end
      rescue => _
        retry_times -= 1
        retry if retry_times.positive?
      end      
    end
  end
end
