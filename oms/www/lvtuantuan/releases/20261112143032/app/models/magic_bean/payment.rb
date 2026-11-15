# frozen_string_literal: true
module MagicBean
  class Payment < ApplicationRecord
    # concerns
    include AASM
    include AASMExtendConcern

    # scope

    # constants

    # attr related macros

    delegate :transaction_id, to: :parent, prefix: true

    enum status: { pending: 1, completed: 2, failure: 3 }
    enum payment_type: { charge: 1, refund: 2 }, _suffix: true

    # 支付来源
    enum channel: {
      mini_program: 1,
      app: 2,
      web: 3
    }

    aasm column: :status, enum: true, requires_lock: true do
      state :pending, initial: true
      state :completed
      state :failure

      event :complete, after: [:increment_parent_refund_amount!, :decrement_parent_refunding_amount!, :update_order_actually_amount_in_cent] do
        transitions from: :pending, to: :completed
      end

      event :fail, after: [:decrement_parent_refunding_amount!] do
        transitions from: :pending, to: :failure
      end
    end

    # association macros
    belongs_to :paymentable, polymorphic: true
    belongs_to :parent, class_name: "Payment", optional: true
    has_many :payments, foreign_key: :parent_id

    # validation macros
    validates :amount_in_cent, numericality: { greater_than: 0 }

    # callbacks
    before_validation :generate_no, on: :create
    after_create :increment_parent_refunding_amount!, if: :refund_payment_type?
    after_commit :enqueue_refund_job, on: :create, if: :refund_payment_type?
    after_create :update_order_payment_type, if: :charge_payment_type?

    # other macros

    # instance methods

    def order
      charge_payment_type? ? paymentable : parent.paymentable
    end

    def refund!
      # 各个子类中实现退款逻辑
      raise "请在子类中实现退款逻辑"
    end

    # 获取 amount_in_cent 的澳币值
    # 微信支付重写改方法
    def aud_amount_in_cent
      amount_in_cent
    end

    # 所有退款都可退手续费
    # 支付金额 - 正在退款金额 - 已退款金额 - 手续费 - 运费 - 上楼服务费
    # 单位由 payment type 决定
    def can_refund_amount(refund_freight = false, refund_service_amount = false, refund_box_regulation_fee = false, refund_package_service_fee = false)
      return 0 unless charge_payment_type? && completed?

      return @can_refund_amount if @can_refund_amount

      @can_refund_amount = amount_in_cent - refunding_amount_in_cent - refund_amount_in_cent
      @can_refund_amount -= order.credit_card_service_amount_in_cent unless refund_service_amount
      
      # 售后不退运费和上楼服务费，不退邮费的情况都是不退上楼费的
      unless paymentable_type == "MagicBean::Order" && refund_freight
        @can_refund_amount = @can_refund_amount - order.freight_in_cent - order.deliver_to_door_service_fee_in_cent
      end
      
      # 整单退款需要退箱规费用、包装服务费, 售后或缺货不退箱规、包装服务费，让用户找客服
      @can_refund_amount -= order.box_regulation_fee_in_cent unless paymentable_type == "MagicBean::Order" && refund_box_regulation_fee
      @can_refund_amount -= order.package_service_fee_in_cent unless paymentable_type == "MagicBean::Order" && refund_package_service_fee

      @can_refund_amount = 0 unless @can_refund_amount.positive?

      @can_refund_amount
    end

    # 订单支付方式
    def order_payment_mode
      raise "请在子类中实现"
    end

    # 固定返回 单位为 $，不同的 payment 可能需要经过换算
    def order_rest_payment_in_cent(refund_service_amount = false, refund_box_regulation_fee = false, refund_package_service_fee = false)
      can_refund_amount(false, refund_service_amount, refund_box_regulation_fee, refund_package_service_fee)
    end

    # 出现了一个售后两次同意退款的情况，所以需要先查找是否存在，不存在再创建
    def generate_refund_payment(wait_to_refund_amount = nil, target_paymentable = nil, refund_freight = false, refund_service_amount = false, refund_box_regulation_fee = false, refund_package_service_fee = false)
      refund_payment = self.class.find_or_create_by(
        paymentable: target_paymentable || self.paymentable,
        parent: self,
        amount_in_cent: wait_to_refund_amount || can_refund_amount(refund_freight, refund_service_amount, refund_box_regulation_fee, refund_package_service_fee),
        payment_type: :refund,
        channel: channel
      )
    end

    # class methods

    # private methods
    private
    def increment_parent_refunding_amount!
      parent.increment!(:refunding_amount_in_cent, amount_in_cent) if pending?
    end

    def decrement_parent_refunding_amount!
      parent.decrement!(:refunding_amount_in_cent, amount_in_cent) if refund_payment_type?
    end

    def increment_parent_refund_amount!
      parent.increment!(:refund_amount_in_cent, amount_in_cent) if refund_payment_type?
    end

    def enqueue_refund_job
      RefundJob.perform_later(id)
    end

    # 更新订单实际支付金额
    # 支付完成后更新实际支付金额
    # 退款触发后减少实际支付金额
    def update_order_actually_amount_in_cent
      if refund_payment_type?
        refund_service_amount = if paymentable_type == "MagicBean::Order"
          paymentable.service_amount_aud_in_cent
        else
          paymentable.after_sales_order_items.sum(:service_amount_in_cent)
        end

        # actually_amount_in_cent是不算手续费的
        # 实际退款金额包含了手续费，需要减去手续费
        refund_amount = aud_amount_in_cent - refund_service_amount
        # 避免actually_amount_in_cent变为负数
        refund_amount = [refund_amount, order.actually_amount_in_cent].min

        order.decrement!(:actually_amount_in_cent, refund_amount)
      end
    end

    def generate_no
      no_prefix = Rails.env.production? ? "p" : "sp"
      loop do
        self.no = no_prefix + Time.current.strftime("%Y%m%d%H%M%L") + rand.to_s[2..4]
        break unless self.class.exists?(no: no)
      end
    end

    def regenerate_no
      generate_no
      self.save
    end

    def update_order_payment_type
      order.update(payment_type: order_payment_mode)
    end
  end
end
