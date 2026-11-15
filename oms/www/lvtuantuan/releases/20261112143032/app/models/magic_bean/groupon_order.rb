# frozen_string_literal: true
module MagicBean
  class GrouponOrder < Order
    include GrouponWechatTemplateDataConcern
    # scope

    # constants

    # attr related macros
    convert_price_to_yuan :price_in_cent

    # association macros
    belongs_to :groupon_activity
    belongs_to :sku_groupon, optional: true
    # 拼团订单支付后才创建拼团，所以这里得添加 optional: true
    belongs_to :groupon, optional: true

    # validation macros
    validate :check_goupon_filled_status, :join_user_can_not_be_creator, :has_joined_groupon, on: :create

    # callbacks
    after_commit :fill_up_groupon, on: :create

    delegate :status, to: :groupon, prefix: true, allow_nil: true
    delegate :user_count, to: :groupon_activity, prefix: true, allow_nil: true

    # other macros

    # 计算应付金额
    def calculate_payment_amount
      # 拼团不能使用优惠券和优惠池
      self.coupon = nil
      self.active_pools = {}

      if virtual_delivery?
        custom_calculate_payment_amount
      else
        super
      end
    end

    def custom_calculate_payment_amount
      self.total_payment_in_cent = amount_in_cent

      self.freight_in_cent = 0
      self.original_freight_in_cent = 0

      self.original_payment_in_cent = amount_in_cent

      self.cost_integral = [cost_integral.to_i, max_cost_integral].min

      self.payment_in_cent = total_payment_in_cent - integral_deducte_amount_in_cent

      # 礼品券使用金额不能超过订单支付金额
      self.gift_card_amount_in_cent = gift_card_coupon ? [gift_card_amount_in_cent.to_i, payment_in_cent, gift_card_coupon.unused_amount_in_cent].min : 0

      self.payment_in_cent -= gift_card_amount_in_cent

      self.wechat_service_percentage = order_payment_setting.wechat_service_percentage

      # 记录当天汇率, 避免后续计算汇率不相同
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

    def is_not_paid?
      wait_buyer_pay?
    end

    def send_wechat_template_message(type)
      # 团员触发支付成功后 拼团就会触发 SendSubscribeMessagesJob, 延迟20s 给团员订阅消息的时间
      delay_at = groupon.finished? ? 20.seconds : 3.seconds
      SendSubscribeMessagesJob.set(wait: delay_at).perform_later(template_message_params(type))
    end

    def order_name
      "拼团订单"
    end

    def enqueue_set_order_confirmed_job
      if groupon_activity.after_activity_ended?
        cot = "#{groupon_activity.end_at.strftime("%Y-%m-%d")} #{CUTOFF_TIME}".in_time_zone
        confirm_time = groupon_activity.end_at < cot ? cot : cot.tomorrow
        SetOrderConfirmedJob.set(wait_until: confirm_time).perform_later(id) if final_amount_in_yuan_num < 1000
      elsif groupon_activity.after_groupon_finished?
        super
      end
    end

    def after_sales_creatable?
      if virtual_delivery?
        ["wait_buyer_confirm_goods", "buyer_confirm_goods", "trade_finished"].include?(status)
      else
        super
      end
    end

    def can_finish_order?
      virtual_delivery? && wait_seller_send_goods? && (groupon.finished? || groupon.free?)
    end

    private

    def generate_order_no
      no_prefix = Rails.env.production? ? "" : "S"
      loop do
        self.no = no_prefix + "G#{Time.now.strftime("%Y%m%d%H%M%L")}#{rand.to_s[2..3]}"
        break unless self.class.exists?(no: no)
      end
    end

    def check_goupon_filled_status
      groupon.with_lock do
        if groupon.groupon_orders.count >= groupon_activity_user_count
          errors.add(:groupon, I18n.t("grape.orders.groupon_is_full"))
        end
      end if groupon
    end

    def join_user_can_not_be_creator
      if groupon && groupon.creator_id == user_id
        errors.add(:base, I18n.t("error.order.cannot_join_your_group"))
      end
    end

    def fill_up_groupon
      groupon.fill_up! if groupon && groupon.may_fill_up? && groupon.groupon_orders.count == groupon_activity_user_count
    end

    def has_joined_groupon
      if groupon && groupon.groupon_orders.exists?(user_id: user_id)
        errors.add(:base, I18n.t("error.order.already_join_group"))
      end
    end

    def additional_pay_success_callbacks
      create_or_finish_groupon
    end

    def create_or_finish_groupon
      if groupon.blank?
        self.groupon = MagicBean::Groupon.creating_by_new_order(self)
        save
      else
        groupon.check_finishing_status
      end
    end

    def additional_close_success_callbacks
      return if groupon.blank?

      if groupon.filled? && groupon.groupon_orders.count < groupon_activity.user_count
        groupon.wait!
      end
    end

    # 拼团订单不能使用优惠券，所以重写了该方法
    def set_coupon_used
    end

    def release_coupon
    end
  end
end
