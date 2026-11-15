# frozen_string_literal: true
module MagicBean
  class AfterSale < ApplicationRecord
    include AASM
    include AASMExtendConcern
    include PriceConvertConcern
    include RefundIntegralConcern
    include PeriodScopeConcern

    # scope
    scope :successful, -> { where(status: %i[wait_buyer_return_goods wait_seller_confirm_goods refunding finished]) }
    # effective 售后记录已经占有能退的货物
    scope :effective, -> { where(status: EFFECTIVE_STATUS) }
    scope :agreed, -> { where(status: AGREED_STATUS) }
    scope :refunded, -> { where(status: %i[refunding finished]) }
    scope :processing, -> { where(status: %i[wait_buyer_return_goods wait_seller_confirm_goods refunding]) }
    scope :processed, -> { where(status: %i[seller_refuse_buyer finished closed]) }

    # constants
    CLOSE_AFTER_SALE_TIME = 3.days
    EFFECTIVE_STATUS = %i[wait_seller_agree wait_buyer_return_goods wait_seller_confirm_goods refunding finished]
    AGREED_STATUS = %i[wait_buyer_return_goods wait_seller_confirm_goods refunding finished]
    REFUND_KEY = "after_sales.amount_in_cent"
    ATTR_I18N_SCOPE = "activerecord.attributes.magic_bean/after_sale".freeze

    # attr related macros
    convert_price_to_yuan :amount_in_cent, :order_freight_in_cent, :order_payment_in_cent, :order_wechat_payment_in_cent,
                          :wechat_amount_in_cent, :original_amount_in_cent, :return_gift_card_amount_in_cent, :return_coupon_amount_in_cent

    enum status: {
      wait_seller_agree: 1,
      wait_buyer_return_goods: 2,
      wait_seller_confirm_goods: 3,
      seller_refuse_buyer: 4,
      refunding: 5,
      finished: 6,
      closed: 7,
      reject_refund: 8
    }

    enum after_sale_type: {
      refund: 1, # 仅退款
      sale_return: 2 # 退货退款
    }

    # 来源
    enum channel: {
      mini_program: 1,
      app: 2,
      web: 3
    }

    # 申请人类型
    enum applicant_type: {
      user: 1,
      wms: 2, # 缺货时系统会发起售后
      admin: 3
    }

    # 退款类型
    enum return_type: {
      normal: 1, # 原支付路径退款
      integral: 2, # 积分退款
      coupon: 3 # 优惠券退款
    }

    # association macros
    belongs_to :user
    belongs_to :order, counter_cache: true
    belongs_to :store
    belongs_to :lastest_operator, class_name: "MagicBean::AdminUser", optional: true

    has_many :after_sales_order_items, dependent: :destroy
    has_many :order_items, through: :after_sales_order_items
    has_many :integral_records, as: :targetable
    has_many :refund_withdraw_integral_records, -> { refund_withdraw }, class_name: "IntegralRecord", as: :targetable
    has_many :payments, dependent: :destroy, as: :paymentable

    # validation macros
    validates :total_quantity, presence: true, numericality: { greater_than: 0 }
    validates :amount_in_cent, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :original_amount_in_cent, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :refund_no, presence: true, uniqueness: true
    validate :validate_amount_in_cent, on: :update
    validate :check_after_sales_order_items, on: :create
    validate :check_order_after_sales_creatable, on: :create

    # callbacks
    before_validation :calculate_refund_amount_and_quantity, on: :create
    # before_validation :calculate_return_integral_amount, on: :update, if: :amount_in_cent_changed?
    before_validation :generate_refund_no, on: :create
    before_validation :set_store_id, on: :create
    before_create :set_channel_and_payment_type
    before_update :adjust_due_time
    after_create :send_admin_after_sale_message_and_notification, if: :admin?

    # other macros
    delegate :no, :payment_in_cent, :receiver_properties, :human_receiver_properties, :id, :total_payment_in_cent, :service_amount_aud_in_cent,
      :freight_in_cent, :type, :cost_integral, :wechat_payment_in_cent, :aud_to_cny_exchange_rate,
      :payment_in_yuan, :wechat_service_percentage, :payment_type, :wechat_payment_in_yuan,
      :credit_card_service_percentage, :credit_card_payment_in_yuan, :credit_card_service_amount_in_yuan, :omipay_service_amount_dollar_in_yuan,
      :omipay_payment_dollar_in_yuan, :omipay_payment_in_yuan, :supay_service_amount_dollar_in_yuan,
      :supay_payment_dollar_in_yuan, :supay_payment_in_yuan, to: :order, prefix: true
    delegate :reward_integral_amount, :all_refund_withdraw_integral_records, :order_paid_integral_records, :completed_charge_payment_channel, :original_spent_channel, to: :order
    delegate :nickname, :origin_nickname, :mobile, :member, :locale, to: :user, prefix: true

    accepts_nested_attributes_for :after_sales_order_items

    ransacker :status, formatter: proc { |v| statuses[v] }
    ransacker :after_sale_type, formatter: proc { |v| after_sale_types[v] }
    ransacker :applicant_type, formatter: proc { |v| applicant_types[v] }
    ransacker :return_type, formatter: proc { |v| return_types[v] }

    aasm column: :status, enum: true do
      state :wait_seller_agree, initial: true
      state :wait_buyer_return_goods
      state :wait_seller_confirm_goods
      state :seller_refuse_buyer
      state :refunding
      state :finished
      state :closed
      state :reject_refund

      # 被拒绝的售后单，不可再次同意，不然可能会出现多退情况
      event :agree do
        transitions from: [:wait_seller_agree],
                    to: :wait_buyer_return_goods,
                    guard: :sale_return?,
                    after: :set_agreed_at,
                    success: [:push_notification_for_sale_return]
        transitions from: [:wait_seller_agree],
                    to: :refunding,
                    guard: :refund?,
                    after: :set_agreed_at,
                    success: [:enqueue_refund_job]
      end

      event :refuse do
        transitions from: :wait_seller_agree,
                    to: :seller_refuse_buyer,
                    after: :set_seller_reply,
                    success: [:push_notification_for_refuse]
      end

      event :close do
        transitions from: [:wait_seller_agree, :wait_buyer_return_goods, :seller_refuse_buyer],
                    to: :closed
      end

      event :return do
        transitions from: :wait_buyer_return_goods,
                    to: :wait_seller_confirm_goods
      end

      event :confirm do
        transitions from: :wait_seller_confirm_goods,
                    to: :refunding,
                    success: [
                      :enqueue_refund_job,
                      :push_notification_for_refund
                    ]
      end

      # 货物不符合退款标准，拒绝退款
      event :reject do
        transitions from: :wait_seller_confirm_goods,
                    to: :reject_refund,
                    success: [:push_notification_for_reject_refund]
      end

      event :drawback, after_commit: [:withdraw_and_return_integral, :withdraw_gift_card_coupon, :send_drawback_wechat_template_message, :finish_order, :generate_after_sale_coupon] do
        transitions from: :refunding,
                    to: :finished
      end
    end

    def update_logistic_info(attributes)
      transaction do
        return false unless update(attributes)
        return false unless perform_aasm_event(:return)

        true
      end
    end

    def full_refund?
      total_quantity == order.quantity
    end

    # 订单是否有拆开发货
    def open_order?
      order.logistics.count > 1
    end

    def stock_keeping_unit_ids
      order_items.map(&:stock_keeping_unit_id)
    end

    def adjust_due_time
      if changed.include?("status")
        # 卖家同意申请之后, 延长3天关闭
        if status == "wait_buyer_return_goods"
          self.due_time = Time.current + CLOSE_AFTER_SALE_TIME
          enqueue_close_after_sale
        # 等待卖家收货，就置空 due_time
        elsif status == "wait_seller_confirm_goods"
          self.due_time = nil
        end
      end
    end

    # 3天后售后订单交易自动关闭
    def enqueue_close_after_sale
      CloseAfterSaleJob.set(wait_until: due_time).perform_later(id)
    end

    def can_show_confirm?
      wait_seller_confirm_goods?
    end

    def last_after_sale?
      order.after_sales.order(created_at: :desc).first.id == id
    end

    # 全退才显示赠品
    def order_human_gifts_properties
      last_after_sale? && all_refund?(total_quantity) ? order.human_gifts_properties : []
    end

    # 全退才显示优惠池赠品
    def order_human_pool_gifts_properties
      last_after_sale? && all_refund?(total_quantity) ? order.human_pool_gifts_properties : []
    end

    def wechat_amount_in_cent
      (amount_in_cent * order_aud_to_cny_exchange_rate).floor
    end

    # refund_fee 直接取 payment 中已经算好的 amount
    def wechat_refund_params
      {
        out_trade_no: order_no,
        out_refund_no: refund_no,
        total_fee: order_wechat_payment_in_cent,
        notify_url: Rails.application.credentials.dig(Rails.env.to_sym, :wechat, :refund_notify_url)
      }
    end

    # 退款完成的纪录
    def completed_refund_payment
      payments.refund_payment_type.completed.first
    end

    def title
      refund_no
    end

    def sort_order_items_by_amount
      @sort_order_items ||= after_sales_order_items.sort_by { |item| -item.real_amount_in_cent }
    end

    private

    def validate_amount_in_cent
      if (amount_in_cent + return_integral_amount + return_coupon_amount_in_cent) > order_total_payment_in_cent + order_service_amount_aud_in_cent
        errors.add(:amount_in_cent, I18n.t("error.after_sale.should_not_be_larger_than_total_amount"))
      elsif amount_in_cent > original_amount_in_cent
        errors.add(:amount_in_cent, I18n.t("error.after_sale.should_not_be_larger_than_original_amount"))
      elsif amount_in_cent != amount_in_cent_was && status != "wait_seller_agree"
        errors.add(:amount_in_cent, I18n.t("error.after_sale.cannot_be_modified"))
      end
    end

    def set_agreed_at
      update(agreed_at: Time.current)
    end

    def generate_refund_no
      no_prefix = Rails.env.production? ? "" : "S"
      loop do
        self.refund_no = no_prefix + Time.now.strftime("%Y%m%d%H%M%L") + rand.to_s[2..4]
        break unless self.class.exists?(refund_no: refund_no)
      end
    end

    def enqueue_refund_job
      self.save(validate: false)
      if amount_in_cent == 0
        drawback! if refunding?
        return
      end

      # 售后也要退手续费, 不退箱规费、包装费
      order.completed_charge_payment.generate_refund_payment(amount_in_cent, self, false, true)
    end

    # 仅创建时调用
    def calculate_refund_amount_and_quantity
      # original_amount_in_cent 能退现金数
      # price_sum: 退款商品的实付总金额（包含现金、礼品卡、金币，不含手续费）
      # cash_amount_sum: 退款现金总额
      # service_amount_sum: 退款服务费总额
      # cost_integral_sum: 退款金币总额
      # gift_card_amount_sum: 退款礼品卡总额
      # ae_gst_amount_sum: 退款GST金额（肯定是现金）
      # total_amount_sum: 总退金额 = price_sum + service_amount_sum
      
      price_sum = after_sales_order_items.sum(&:real_amount_in_cent)
      quantity_sum = after_sales_order_items.sum(&:quantity)
      service_amount_sum = after_sales_order_items.sum(&:service_amount_in_cent)
      cash_amount_sum = after_sales_order_items.sum(&:cash_amount_in_cent)
      ae_gst_amount_sum = after_sales_order_items.sum(&:ae_gst_amount_in_cent)
      total_amount_sum = price_sum + service_amount_sum + ae_gst_amount_sum

      # order_rest_payment_in_cent不算上手续费的，所以这里要加上service_amount_sum
      self.original_amount_in_cent = [total_amount_sum, order_rest_payment_in_cent + service_amount_sum].min

      if integral?
        self.return_integral_amount = exchange_aus_dollar_to_integral(total_amount_sum)
        self.amount_in_cent = 0
      elsif coupon?
        self.return_coupon_amount_in_cent = total_amount_sum
        self.amount_in_cent = 0
      else
        # 需要兼容旧数据，需要先比对各项金额是否够退
        cost_integral_sum = after_sales_order_items.sum(&:cost_integral)
        gift_card_amount_sum = after_sales_order_items.sum(&:gift_card_amount_in_cent)
        
        reset_amount = 0

        # 先比对现金，多的部分加到礼品卡，再比对礼品卡，多的部分加到金币上
        # 实际现金 = 现金 + GST + 服务费
        real_cash_amount_sum = cash_amount_sum + ae_gst_amount_sum + service_amount_sum
        if real_cash_amount_sum > original_amount_in_cent
          reset_amount = real_cash_amount_sum - original_amount_in_cent
          self.amount_in_cent = original_amount_in_cent
        else
          self.amount_in_cent = real_cash_amount_sum
        end

        if gift_card_amount_sum + reset_amount > can_return_gift_card_amount_in_cent
          reset_amount = gift_card_amount_sum + reset_amount - can_return_gift_card_amount_in_cent
          self.return_gift_card_amount_in_cent = can_return_gift_card_amount_in_cent
        else
          self.return_gift_card_amount_in_cent = gift_card_amount_sum + reset_amount
        end

        self.return_integral_amount = cost_integral_sum + exchange_aus_dollar_to_integral(reset_amount)
      end

      self.total_quantity = quantity_sum
    end

     # 修改售后订单项金额时调用
     def calculate_refund_amount_and_quantity_on_update
      # original_amount_in_cent 能退现金数
      # price_sum: 退款商品的实付总金额（包含现金、礼品卡、金币，不含手续费）
      # cash_amount_sum: 退款现金总额
      # service_amount_sum: 退款服务费总额
      # cost_integral_sum: 退款金币总额
      # gift_card_amount_sum: 退款礼品卡总额
      # ae_gst_amount_sum: 退款GST金额（肯定是现金）
      # total_amount_sum: 总退金额 = price_sum + service_amount_sum + ae_gst_amount_sum
      price_sum = after_sales_order_items.sum(&:real_amount_in_cent)
      quantity_sum = after_sales_order_items.sum(&:quantity)
      service_amount_sum = after_sales_order_items.sum(&:service_amount_in_cent)
      cash_amount_sum = after_sales_order_items.sum(&:cash_amount_in_cent)
      ae_gst_amount_sum = after_sales_order_items.sum(&:ae_gst_amount_in_cent)
      total_amount_sum = price_sum + service_amount_sum + ae_gst_amount_sum

      # order_rest_payment_in_cent不算上手续费的，所以这里要加上service_amount_sum
      self.original_amount_in_cent = [total_amount_sum, order_rest_payment_in_cent + service_amount_sum].min

      if integral?
        self.return_integral_amount = exchange_aus_dollar_to_integral(total_amount_sum)
        self.amount_in_cent = 0
      elsif coupon?
        self.return_coupon_amount_in_cent = total_amount_sum
        self.amount_in_cent = 0
      else
        # 修改金额一定比原金额小，不需要比对
        cost_integral_sum = after_sales_order_items.sum(&:cost_integral)
        gift_card_amount_sum = after_sales_order_items.sum(&:gift_card_amount_in_cent)
        self.amount_in_cent = cash_amount_sum + service_amount_sum + ae_gst_amount_sum
        self.return_gift_card_amount_in_cent = gift_card_amount_sum
        self.return_integral_amount = cost_integral_sum
      end

      self.total_quantity = quantity_sum
    end

    # 可退金额 + 可退金币 + 可退礼品卡 - 已退优惠券
    def can_return_amount_in_cent
      order_rest_payment_in_cent + can_return_integral_amount_in_cent(actual_return_integral_amount) + can_return_gift_card_amount_in_cent - refunded_coupon_amount_in_cent
    end

    # 这个方法需要应用到can_return_amount_in_cent
    def actual_return_integral_amount
      order.cost_integral - refunded_after_sales.sum(:return_integral_amount)
    end

    # 如果订单没用金币，后台退款选了金币，则can_return_integral_amount会是负数
    def can_return_integral_amount
      amount = actual_return_integral_amount
      amount.negative? ? 0 : amount
    end

    def can_return_integral_amount_in_cent(custom_integral_amount = nil)
      exchange_integral_to_aus_dollar(custom_integral_amount || can_return_integral_amount)
    end

    def can_return_gift_card_amount_in_cent
      order.gift_card_amount_in_cent - refunded_after_sales.sum(:return_gift_card_amount_in_cent)
    end

    def refunded_coupon_amount_in_cent
      refunded_after_sales.coupon.sum(:return_coupon_amount_in_cent)
    end

    def exchange_aus_dollar_to_integral(amount)
      (amount.to_f / 100 * order.integral_deducted_from_one_yuan).round
    end

    def exchange_integral_to_aus_dollar(integral)
      (integral.to_f * 100 / order.integral_deducted_from_one_yuan).round
    end

    # 该方法没有调用
    def get_refund_data_on_update
      price_sum = after_sales_order_items.sum { |item| item.quantity * item.order_item.real_price_in_cent }
      quantity_sum = after_sales_order_items.sum(&:quantity)

      # 先退积分，再退礼品卡，再退现金
      # 需统一金额单位  price_sum 计算出来的为 $,
      # 此处金额存为 $
      # 这里为了防止多退的情况
      original_amount = [price_sum, order_rest_payment_in_cent].min
      [price_sum, quantity_sum, original_amount]
    end

    def agreed_after_sales
      order.after_sales.where.not(id: self.id)
        .where(status: ["wait_buyer_return_goods", "refunding", "finished"])
    end

    def all_refund?(quantity_sum)
      agreed_after_sales.sum(:total_quantity) + quantity_sum == order.quantity
    end

    def amount_not_changed?
      agreed_after_sales.sum(:original_amount_in_cent) == agreed_after_sales.sum(:amount_in_cent)
    end

    # 不包含手续费、箱规费、包装费
    def order_rest_payment_in_cent
      @order_rest_payment_in_cent ||= order.completed_charge_payment&.order_rest_payment_in_cent.to_i
    end

    def order_effective_after_sales
      order.after_sales.effective.where.not(id: id)
    end

    def refunded_after_sales
      order.after_sales.refunded.where.not(id: id)
    end

    def set_seller_reply
      update(seller_reply: seller_reply)
    end

    def send_drawback_wechat_template_message
      SendSubscribeMessagesJob.perform_later(template_message_params)
    end

    def template_message_params
      {
        touser: user.open_id,
        page: mini_program_path,
        type: "refund",
        data: template_data,
        targetable_type: self.class.name,
        targetable_id: self.id,
        user_id: user.id
      }
    end

    def mini_program_path
      "pages/after-sale/detail/detail?id=#{id}"
    end

    def app_path
      { type: "afterSale", params: { id: id } }.to_json
    end

    # 订单号 11889
    # 退款编号 400120171203116
    # 商品名称 保健护肤品
    # 退款金额 20元
    # 退款说明 退款已经原路返回, 其中 20 元将退回到余额
    def template_data
      {
        "character_string2": {
          value: order_no
        },
        "thing5": {
          value: order_items.pluck(:title).join(",")
        },
        "amount3": {
          value: "#{amount_in_yuan}元"
        },
        "thing1": {
          value: "审核通过，退款中"
        },
        "thing6": {
          value: template_remark
        }
      }
    end

    def template_remark
      "退款已经原路返回"
    end

    def refund_application_title
      @refund_application_title ||= I18n.t(
        "refund_titles.refund_application", scope: ATTR_I18N_SCOPE, locale: user_locale
      )
    end

    def refund_result_title
      @refund_result_title ||= I18n.t(
        "refund_titles.refund_result", scope: ATTR_I18N_SCOPE, locale: user_locale
      )
    end

    def return_receiver_properties
      @return_receiver_properties ||= default_site_config&.human_return_receiver_properties
    end

    def mobile
      order.receiver_properties["tel_number"]
    end

    def default_site_config
      @default_site_config ||= MagicBean::SiteConfig.default_config
    end

    def send_sms_message(message)
      SmsJob.perform_later(mobile, message)
    end

    def send_message_for_refund
      return unless refunding?

      message = I18n.t("refund_messages.refund_approved", scope: ATTR_I18N_SCOPE, locale: user_locale)
      send_sms_message(message)
    end

    def send_message_for_reject_refund
      message = I18n.t("refund_messages.sale_return_rejected", scope: ATTR_I18N_SCOPE, locale: user_locale, seller_reply: seller_reply)
      send_sms_message(message)
    end

    def send_message_for_sale_return
      message = I18n.t("refund_messages.sale_return_approved", scope: ATTR_I18N_SCOPE, locale: user_locale, return_receiver_properties: return_receiver_properties)
      send_sms_message(message)
    end

    def send_message_for_refuse
      message = I18n.t("refund_messages.refund_rejected", scope: ATTR_I18N_SCOPE, locale: user_locale, seller_reply: seller_reply)
      send_sms_message(message)
    end

    def push_notification_for_refund
      return unless refunding?

      message = I18n.t("refund_messages.refund_approved", scope: ATTR_I18N_SCOPE, locale: user_locale)
      ::MagicBean::AppNotifier.enqueue_app_push_job(refund_result_title, message, user_id, app_link: app_path)
    end

    def push_notification_for_reject_refund
      message = I18n.t("refund_messages.sale_return_rejected", scope: ATTR_I18N_SCOPE, locale: user_locale)
      ::MagicBean::AppNotifier.enqueue_app_push_job(refund_application_title, message, user_id, app_link: app_path)
    end

    def push_notification_for_sale_return
      message = I18n.t("refund_messages.sale_return_approved", scope: ATTR_I18N_SCOPE, locale: user_locale, return_receiver_properties: return_receiver_properties)
      ::MagicBean::AppNotifier.enqueue_app_push_job(refund_application_title, message, user_id, app_link: app_path)
    end

    def push_notification_for_refuse
      message = I18n.t("refund_messages.sale_return_rejected", scope: ATTR_I18N_SCOPE, locale: user_locale)
      ::MagicBean::AppNotifier.enqueue_app_push_job(refund_application_title, message, user_id, app_link: app_path)
    end

    # 同意退款时也需要检查这个方法
    def check_after_sales_order_items
      order.with_lock do
        order_items_mapping = order.order_items.group(:id).sum(:quantity)
        after_sales_order_items_mapping = MagicBean::AfterSalesOrderItem.where(after_sale: order.after_sales.effective).group(:order_item_id).sum(:quantity)

        # OMS一个商品可能会误选多次，所以这里重新处理下数据
        order_items_hash = {}
        after_sales_order_items.each do |item|
          order_items_hash[item.order_item_id] ||= { title: item.order_item.title, quantity: 0 }
          order_items_hash[item.order_item_id][:quantity] += item.quantity
        end

        order_items_hash.each do |order_item_id, item|
          if item[:quantity] + (after_sales_order_items_mapping[order_item_id] || 0) > order_items_mapping[order_item_id]
            errors.add(:base, I18n.t("errors.some_products_are_in_process", scope: ATTR_I18N_SCOPE, item_title: item[:title]))
          end
        end
      end
    end

    def check_order_after_sales_creatable
      return if order.after_sales_creatable?

      errors.add(:base, I18n.t("errors.can_not_be_created", scope: ATTR_I18N_SCOPE, locale: user_locale))
    end

    def finish_order
      # 若订单状态可以被更新为“已完成”并且为售后为“全部退货”
      # 则提前完成订单
      if order.may_finish? && !order.part_refund?
        order.finish!
      end
    end

    def can_not_agree_or_refuse?
      # 售后单项中如果有未发货的，则不能 同意/拒绝售后
      open_order? && (stock_keeping_unit_ids - order.logistics.pluck(:sku_ids).flatten).present?
    end

    # 需求是售后暂时不回滚库存，这里也暂时不写优惠池赠品回滚逻辑
    def increase_inventory!
      after_sales_order_items.map(&:increase_inventory!) unless wms?
      # 全部退回时需增加赠品库存
      order.gifts.each do |gift|
        gift[:sku]&.increase_inventory!(gift[:quantity])
      end if order.gifts.present? && all_refund?(total_quantity)
    end

    def set_channel_and_payment_type
      self.channel = order.channel
      self.payment_type = order.payment_type
    end

    def set_store_id
      self.store_id = order.store_id
    end

    def withdraw_gift_card_coupon
      if return_gift_card_amount_in_cent.positive?
        gift_card_coupon = order.gift_card_coupon
        gift_card_coupon.update(used_amount_in_cent: gift_card_coupon.used_amount_in_cent - return_gift_card_amount_in_cent, status: :pending)
      end
    end

    def send_admin_after_sale_message_and_notification
      original_locale = I18n.locale
      I18n.locale = user_locale

      order.send_admin_create_after_sale_notification(after_sales_order_items, return_type)

      I18n.locale = original_locale
    end

    def generate_after_sale_coupon
      return unless coupon? && return_coupon_amount_in_cent.positive?
      template = MagicBean::CouponTemplate.create(
        title_zh_cn: "售后优惠券 $#{return_coupon_amount_in_yuan}",
        title_zh_tw: "售後優惠券 $#{return_coupon_amount_in_yuan}",
        title_en: "",
        kind: :reduction,
        denominations_in_cent: return_coupon_amount_in_cent,
        time_kind: :fixed_period,
        start_at: Time.current,
        end_at: Time.current + 60.days,
        details_image: "https://cdn.minimall.donkibuy.com/images/220712/ec2veike7.png?x-oss-process=image/resize,w_750/quality,q_100",
        user_kind: :all_user,
        store_id: store_id,
        usage_kind: :after_sale,
        cost_accounting: :platform
      )
      template.generate_coupons_and_assign_to_users([user_id])
    end
  end
end
