# frozen_string_literal: true
module MagicBean
  class OrderItem < ApplicationRecord
    include PriceConvertConcern
    include InventoryConcern
    # scope
    # 订单状态不是关闭情况下算作商品卖出
    scope :sold_in_last_30_days, -> { joins(:order).where("orders.created_at > ? AND orders.status != 6", 30.days.ago.beginning_of_day) }
    scope :normal_order, -> { joins(:order).where(orders: { type: "MagicBean::NormalOrder" }) }
    scope :groupon, -> { joins(:order).where(orders: { type: "MagicBean::GrouponOrder" }) }
    scope :virtual_order, -> { joins(:order).where(orders: { type: "MagicBean::VirtualOrder" }) }

    # constants
    attr_accessor :is_gift

    # attr related macros
    delegate :category_name, :parent_category_name, :no, :title, to: :item, prefix: true
    delegate :item_type, :delivery_type, :coupon_enabled, :free_shipping, :storage_method, :gift_card_enabled, :expiration_date, :expiration_reminder_before_n_days, to: :item
    delegate :cover, :sub_title, :brand_name, :barcode, :width_in_cm, :length_in_cm, :height_in_cm, :human_title, to: :stock_keeping_unit
    delegate :no, to: :stock_keeping_unit, prefix: true

    convert_price_to_yuan :amount_in_cent, :price_in_cent, :strikethrough_price_in_cent, :real_price_in_cent, :real_amount_in_cent, :display_price_in_cent, :real_display_amount_in_cent, :strikethrough_amount_in_cent, :service_amount_in_cent, :gift_card_amount_in_cent, :cash_amount_in_cent, :ae_gst_amount_in_cent

    enum sku_type: {
      normal: 1,
      auction: 2,
      same_day_delivery: 3
    }

    enum marketing_mode: {
      self_support: 1,
      consign_for_sale: 2,
      platform: 3
    }

    enum source_page_name: {
      home: 1,
      banner: 2,
      custom_page: 3,
      category: 4,
      item_like: 5,
      item_search: 6,
      order_list: 7,
      recommend_items: 8,
      preferential_pool: 9,
      auction_activity: 10,
      user_history: 11,
      hot_sell_list: 12 # 热卖榜
    }

    enum source_channel: {
      mini_program: 1,
      app: 2,
      web: 3
    }

    # association macros
    belongs_to :order
    belongs_to :item
    belongs_to :stock_keeping_unit
    belongs_to :store
    belongs_to :promo_code, optional: true
    has_many :after_sales_order_items
    has_many :effective_after_sales_order_items, -> { effective }, class_name: "AfterSalesOrderItem"
    has_many :refunded_after_sales_order_items, -> { refunded }, class_name: "AfterSalesOrderItem"
    has_many :wms_refunded_after_sales_order_items, -> { wms_refunded }, class_name: "AfterSalesOrderItem"
    has_many :after_sales, through: :after_sales_order_items
    has_many :successful_after_sales, -> { where(status: [:refunding, :finished]) }, through: :after_sales_order_items, source: :after_sale
    has_many :comments, as: :commentable

    # validation macros
    validate :validate_inventory
    validate :check_item_listing_type, :check_item_channel, on: :create
    validates :weight_in_gram, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :quantity, presence: true, numericality: { greater_than: 0 }

    # callbacks
    before_validation :calculate_amount, :calculate_real_price, :set_store_id, :set_marketing_mode, :set_quantity

    # other macros

    def calculate_amount
      self.amount_in_cent = price_in_cent * quantity
      self.strikethrough_amount_in_cent = strikethrough_price_in_cent * quantity
    end

    def enough_inventory?
      stock_keeping_unit.quantity >= quantity
    end

    def coupon
      order.coupon if order.is_a?(MagicBean::NormalOrder)
    end

    # real_amount_in_cent: 用于展示，(现金 + 礼品卡 + 金币 - 优惠券) 再按比例分配
    def calculate_real_price
      if item.coupon_enabled
        self.real_price_in_cent = (coupon && coupon.item?) ? coupon.calculate_order_item_base_price_in_cent(self).floor : (pool_price_in_cent || price_in_cent)
      else
        self.real_price_in_cent = pool_price_in_cent || price_in_cent
      end
      self.real_amount_in_cent = real_price_in_cent.to_i * quantity
      set_gst_value
    end

    def calculate_display_price
      if order.cost_integral.to_i.positive?
        self.display_price_in_cent = real_price_in_cent - (order.integral_deducte_amount_in_cent * real_price_in_cent.to_f / order.order_items_real_amount).floor
      else
        self.display_price_in_cent = real_price_in_cent
      end
    end

    # 优惠池优惠后的价格
    def pool_amount_in_cent
      pool_price_in_cent.to_i * quantity
    end

    # 用于展示，(现金 + 礼品卡 - 优惠券 - 金币) 再按比例分配
    def real_display_amount_in_cent
      display_price_in_cent.to_i * quantity
    end

    # increment!不会触发item的before_save
    def increase_sales_count!
      item = stock_keeping_unit.item.reload
      item.update(sales_count: item.sales_count + quantity, actual_monthly_sales_count: item.actual_monthly_sales_count + quantity)
    end

    def decrease_sales_count!
      item = stock_keeping_unit.item.reload
      item.update(sales_count: item.sales_count - quantity, actual_monthly_sales_count: item.actual_monthly_sales_count - quantity)
    end

    def refund_quantity
      effective_after_sales_order_items.sum { |asoi| asoi.quantity }.to_i
    end

    def gst_amount_in_yuan
      gst_amount_in_cent / 100.0
    end

    def sku_human_title
      "#{title} - #{properties_text}"
    end

    # 特殊包装：1，送货上楼: 2
    # 需要先判断仓储订单的上货上门字段
    def packing_instruction_type
      # 赠品的话order为空
      (order&.warehouse_order&.deliver_to_door || order&.deliver_to_door) ? [2] : []
    end

    # 传值保冰袋、礼盒包装
    def packing_instruction
      []
    end

    def cash_amount_in_cent
      cash_amount = real_amount_in_cent - gift_card_amount_in_cent - exchange_integral_to_aus_dollar(cost_integral)
      cash_amount.positive? ? cash_amount : 0
    end

    private

    def validate_inventory
      errors[:base] << " #{sku_human_title} #{I18n.t("grape.orders.insufficient_inventory")} " unless enough_inventory?
    end

    def check_item_listing_type
      # 拍卖订单的商品不会上架，所以跳过在售校验
      return true if order.type == "MagicBean::AuctionOrder"

      errors[:base] << I18n.t("error.order.sku_offline", sku_title: sku_human_title) unless item.on_sale_base_listing_type? && stock_keeping_unit.on_sale?
    end

    def check_item_channel
      errors[:base] << I18n.t("error.order.sale_channel", sku_title: stock_keeping_unit.human_title, channel: item.channels_text) unless item.channel_match?(order.channel)
    end

    def set_store_id
      self.store_id = stock_keeping_unit.store_id
    end

    def set_gst_value
      self.gst_percent = stock_keeping_unit.gst_percent
      self.gst_amount_in_cent = (real_amount_in_cent.to_f / (100 + gst_percent) * gst_percent).round(2)
    end

    def set_marketing_mode
      self.marketing_mode = stock_keeping_unit.marketing_mode
    end

    def set_quantity
      self.quantity = 1 unless quantity.positive?
    end

    def exchange_integral_to_aus_dollar(integral)
      (integral.to_f * 100 / order.integral_deducted_from_one_yuan).round
    end
  end
end
