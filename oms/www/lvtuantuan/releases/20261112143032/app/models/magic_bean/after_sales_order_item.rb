# frozen_string_literal: true
module MagicBean
  class AfterSalesOrderItem < ApplicationRecord
    include InventoryConcern
    include PriceConvertConcern

    # scope
    scope :valid, -> { includes(:after_sale).where("after_sales.status": "finished") }
    scope :refunded, -> { includes(:after_sale).where("after_sales.status": %i[refunding finished]) }
    scope :wms_refunded, -> { includes(:after_sale).where("after_sales.status": %i[refunding finished], "after_sales.applicant_type": "wms") }
    scope :effective, -> { includes(:after_sale).where("after_sales.status": AfterSale::EFFECTIVE_STATUS) }

    # constants

    # attr related macros
    convert_price_to_yuan :real_amount_in_cent, :cash_amount_in_cent, :service_amount_in_cent, :gift_card_amount_in_cent, :max_cash_amount_in_cent, :max_gift_card_amount_in_cent, :max_service_amount_in_cent, :ae_gst_amount_in_cent, :max_ae_gst_amount_in_cent

    # association macros
    belongs_to :order_item
    belongs_to :after_sale

    # validation macros
    validate :check_amount_valid, on: :update

    # callbacks
    after_initialize :set_amount_columns

    # other macros
    delegate :item_title, :stock_keeping_unit_no, :stock_keeping_unit_id, :real_price_in_cent, to: :order_item

    def stock_keeping_unit
      order_item.stock_keeping_unit
    end

    def set_amount_columns
      if new_record?
        # order_item的real_amount_in_cent/quantity如果除不尽的话，real_price_in_cent会偏大，所以这里需要取real_amount_in_cent来计算，不能用real_price_in_cent
        self.real_amount_in_cent = (order_item.real_amount_in_cent * quantity / order_item.quantity.to_f).floor
        self.service_amount_in_cent = (order_item.service_amount_in_cent * quantity / order_item.quantity.to_f).floor
        self.cost_integral = (order_item.cost_integral * quantity / order_item.quantity.to_f).floor
        self.gift_card_amount_in_cent = (order_item.gift_card_amount_in_cent * quantity / order_item.quantity.to_f).floor
        self.ae_gst_amount_in_cent = (order_item.ae_gst_amount_in_cent * quantity / order_item.quantity.to_f).floor
        
        # 判断退款数量是否等于剩余数量，如果是，则退款金额等于剩余金额
        # 以service_amount_in_cent为例，上面计算出来的值可能会除不尽，所以如果是整单退款的话，需要把剩余的金额加到退款金额上
        # 如果正在生效的售后已经计算了余数，那么这里就不需要再计算了
        if !effective_after_sales_contain_remainder? && effective_after_sales_quantity.positive? && (quantity + effective_after_sales_quantity == order_item.quantity)
          self.real_amount_in_cent = order_item.real_amount_in_cent - effective_after_sales_original_real_amount
          # 上面计算的service_amount_in_cent / quantity * order_item.quantity, 就得到了不加余数的service_amount_in_cent总额，再用order_item.service_amount_in_cent减去这个值，就得到了余数
          self.service_amount_in_cent = order_item.service_amount_in_cent - effective_after_sales_max_service_amount
          self.cost_integral = order_item.cost_integral - effective_after_sales_max_cost_integral
          self.gift_card_amount_in_cent = order_item.gift_card_amount_in_cent - effective_after_sales_max_gift_card_amount
          self.ae_gst_amount_in_cent = order_item.ae_gst_amount_in_cent - effective_after_sales_max_ae_gst_amount
          
          self.contain_remainder = true
        end
        # 现金 = real_amount - 礼品卡 - 金币
        self.cash_amount_in_cent = real_amount_in_cent - gift_card_amount_in_cent - after_sale.send(:exchange_integral_to_aus_dollar, cost_integral)
        self.cash_amount_in_cent = 0 if cash_amount_in_cent.negative?
        
        # 创建时计算的金额为最大可退金额
        self.max_service_amount_in_cent = service_amount_in_cent
        self.max_cost_integral = cost_integral
        self.max_gift_card_amount_in_cent = gift_card_amount_in_cent
        self.max_cash_amount_in_cent = cash_amount_in_cent
        self.max_ae_gst_amount_in_cent = ae_gst_amount_in_cent
        self.original_real_amount_in_cent = real_amount_in_cent
      end
    end

    private
    def effective_after_sales_order_items
      @effective_after_sales ||= MagicBean::AfterSalesOrderItem.where(after_sale_id: after_sale.send(:order_effective_after_sales).select(:id), order_item_id: order_item_id)
    end

    # 减少查询，用map后再sum
    def effective_after_sales_quantity
      effective_after_sales_order_items.map(&:quantity).sum
    end

    def effective_after_sales_contain_remainder?
      effective_after_sales_order_items.map(&:contain_remainder).any?(true)
    end

    def effective_after_sales_original_real_amount
      effective_after_sales_order_items.map(&:original_real_amount_in_cent).sum
    end

    def effective_after_sales_max_service_amount
      effective_after_sales_order_items.map(&:max_service_amount_in_cent).sum
    end

    def effective_after_sales_max_cost_integral
      effective_after_sales_order_items.map(&:max_cost_integral).sum
    end

    def effective_after_sales_max_gift_card_amount
      effective_after_sales_order_items.map(&:max_gift_card_amount_in_cent).sum
    end

    def effective_after_sales_max_ae_gst_amount
      effective_after_sales_order_items.map(&:max_ae_gst_amount_in_cent).sum
    end

    def check_amount_valid
      # 如果修改了数量，就不管金额
      if quantity_changed?
        # 修改数量需要校验数量不能大于原数量
        if quantity > quantity_was
          after_sale.errors.add(:base, "退款数量不能大于原数量: #{quantity_was}")
        else
          # 按比例计算金额，然后向下取整
          self.contain_remainder = false
          self.real_amount_in_cent = (real_amount_in_cent.to_f / quantity_was * quantity).floor
          self.service_amount_in_cent = (service_amount_in_cent.to_f / quantity_was * quantity).floor
          self.cost_integral = (cost_integral.to_f / quantity_was * quantity).floor
          self.gift_card_amount_in_cent = (gift_card_amount_in_cent.to_f / quantity_was * quantity).floor
          self.cash_amount_in_cent = (cash_amount_in_cent.to_f / quantity_was * quantity).floor
          self.ae_gst_amount_in_cent = (ae_gst_amount_in_cent.to_f / quantity_was * quantity).floor
          self.max_service_amount_in_cent = service_amount_in_cent
          self.max_cost_integral = cost_integral
          self.max_gift_card_amount_in_cent = gift_card_amount_in_cent
          self.max_cash_amount_in_cent = cash_amount_in_cent
          self.original_real_amount_in_cent = real_amount_in_cent
        end
      else
        # 修改金额需要校验金额不能大于初始值
        after_sale.errors.add(:base, "退款现金不能大于$#{max_cash_amount_in_yuan}") if cash_amount_in_cent > max_cash_amount_in_cent
        after_sale.errors.add(:base, "退款手续费不能大于$#{max_service_amount_in_yuan}") if service_amount_in_cent > max_service_amount_in_cent
        after_sale.errors.add(:base, "退款礼品卡不能大于$#{max_gift_card_amount_in_yuan}") if gift_card_amount_in_cent > max_gift_card_amount_in_cent
        after_sale.errors.add(:base, "退款金币不能大于$#{max_cost_integral}") if cost_integral > max_cost_integral
        after_sale.errors.add(:base, "退款GST金额不能大于$#{max_ae_gst_amount_in_yuan}") if ae_gst_amount_in_cent > max_ae_gst_amount_in_cent
        self.real_amount_in_cent = cash_amount_in_cent + gift_card_amount_in_cent + after_sale.send(:exchange_integral_to_aus_dollar, cost_integral)
      end

       # 需要触发after_sale calculate_refund_amount_and_quantity方法重新计算calculate_refund_amount_and_quantity金额
       after_sale.send :calculate_refund_amount_and_quantity_on_update
    end
  end
end
