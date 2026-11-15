# frozen_string_literal: true
module MagicBean
  class VirtualOrder < Order
    # scope

    # constants

    # attr related macros

    # association macros

    # validation macros

    # callbacks

    # other macros

    def order_name
      "虚拟产品订单"
    end

    def calculate_payment_amount(calculate_cost_integral = true)
      self.total_payment_in_cent = amount_in_cent

      if active_pools.present? && (active_pools["discount"].present? || active_pools["reduction"].present?)
        self.total_payment_in_cent -= pool_discount_amount_in_cent
      end

      # 计算商品价格
      self.total_payment_in_cent = coupon.calculate_discount_payment(self).ceil if coupon && coupon.item?

      self.freight_in_cent = 0
      self.original_freight_in_cent = 0

      self.original_payment_in_cent = amount_in_cent

      if calculate_cost_integral
        self.cost_integral = [cost_integral.to_i, max_cost_integral].min
      end
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

    # 虚拟产品不需要同步wms
    def enqueue_set_order_confirmed_job; end

    def human_receiver_properties
      return nil if receiver_properties.blank?
      "#{full_receiver_address} #{receiver_name} #{receiver_tel_number} #{receiver_email}"
    end

    def after_sales_creatable?
      ["wait_buyer_confirm_goods", "buyer_confirm_goods", "trade_finished"].include?(status)
    end

    private

    def generate_order_no
      no_prefix = Rails.env.production? ? "" : "S"
      loop do
        self.no = no_prefix + "V#{Time.now.strftime("%Y%m%d%H%M%L")}#{rand.to_s[2..3]}"
        break unless self.class.exists?(no: no)
      end
    end

    def check_delivery_type
      errors.add(:base, I18n.t("error.order.delivery_type_not_correct")) unless virtual_delivery?
    end
  end
end
