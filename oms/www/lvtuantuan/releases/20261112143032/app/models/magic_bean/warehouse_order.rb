# frozen_string_literal: true

module MagicBean
  class WarehouseOrder < ApplicationRecord
    # constants
    APPEND_FEILDS = %w[buyer_message remark]

    # concerns
    include AASM

    # attr related macros
    # 同步 wms 状态
    enum sync_status: {
      pending: 1,    # 待管理员确认订单
      confirmed: 2,  # 待同步到 wms，，默认 confirmed，只有已确认订单才会生成仓储订单
      synced: 3,     # 已同步到 wms
      stockout: 4
    }
    ransacker :sync_status, formatter: proc { |v| sync_statuses[v] }
    aasm :sync_status, column: :sync_status, enum: true, requires_lock: true do
      state :pending # pending 状态只是为了跟销售订单的保持致。目前不会有 pending 状态的仓储订单，因为只有已确认的销售订单才会生成仓储订单
      state :confirmed, initial: true
      state :synced
      state :stockout

      event :sync do
        transitions from: :confirmed, to: :synced
      end

      event :sellout do
        transitions from: [:confirmed, :synced], to: :stockout
      end
    end

    enum channel: {
      mini_program: 1,
      app: 2,
      web: 3,
      shopline: 4,
      # aliexpress: 5
    }

    enum delivery_type: {
      merchant_delivery: 1,
      express: 2,
      self_pick: 3,
      virtual_delivery: 4
    }

    ransacker :sync_status, formatter: proc { |v| sync_statuses[v] }
    ransacker :delivery_type, formatter: proc { |v| delivery_types[v] }
    ransacker :channel, formatter: proc { |v| channels[v] }

    # association macros
    belongs_to :user, optional: true
    belongs_to :store

    has_many :orders, dependent: :nullify
    has_many :shopline_orders, -> { shopline }, class_name: "MagicBean::ThirdPartyOrder", dependent: :nullify

    # validation macros
    validates :no, presence: true, uniqueness: true

    # callbacks
    before_validation :generate_order_no, on: :create

    # other macros
    delegate :name, to: :store, prefix: true

    # scopes

    # class methods

    # instance methods
    MagicBean::Order::RECEIVER_PROPERTIES.each do |attr_name|
      perfix_attr_name = "receiver_#{attr_name}"
      define_method perfix_attr_name do
        @perfix_attr_name = receiver_properties&.dig(attr_name)&.strip
      end
    end

    # jerry 要求将地址切割成3行，每行不超过40字符
    def shipping_address_1
      @shipping_address_1 ||= receiver_detail_info[0, 40]
    end

    def shipping_address_2
      @shipping_address_2 ||= receiver_detail_info[40, 40]
    end

    def shipping_address_3
      @shipping_address_3 ||= receiver_detail_info[80, 40]
    end

    def human_receiver_properties
      return nil if receiver_properties.nil?
      "#{receiver_detail_info} #{receiver_city_name} #{receiver_province_name} #{receiver_postal_code} #{receiver_first_name} #{receiver_last_name} #{receiver_tel_number}"
    end

    def order_items_with_gifts
      return @order_items_with_gifts if @order_items_with_gifts.present?
      @order_items_with_gifts = []
      
      if shopline?
        order_store_id = shopline_orders.first.store_id
        shopline_orders.map(&:order_items).flatten.each do |order_item|
          sku = MagicBean::StockKeepingUnit.find_by(no: order_item["sku"], store_id: order_store_id)
          next unless sku
          amount = (order_item["price"].to_f * order_item["quantity"]).round(2)
          gst_amount = (amount / (100 + sku.gst_percent) * sku.gst_percent).round(2)
          @order_items_with_gifts << {
            stock_keeping_unit_id: sku.id,
            stock_keeping_unit_no: order_item["sku"],
            properties_text: order_item["variant_title"],
            brand_name: order_item["vendor"],
            title: order_item["title"],
            sub_title: nil,
            short_title: nil,
            barcode: sku.barcode,
            weight_in_gram: order_item["grams"],
            height_in_cm: sku.height_in_cm,
            length_in_cm: sku.length_in_cm,
            width_in_cm: sku.width_in_cm,
            quantity: order_item["quantity"],
            price_in_yuan: order_item["price"],
            amount_in_yuan: amount,
            gst_amount_in_yuan: gst_amount,
            is_gift: false,
            packing_instruction_type: [],
            packing_instruction: []
          }
        end.compact
      else
        # 将相同sku的订单项合并
        # 有些is_gift为nil, 所以判断一下
        orders.map(&:order_items_with_gifts).flatten.group_by { |order_item| [order_item.stock_keeping_unit_id, order_item.is_gift == true ? true : false] }.each do |key, order_items|
          tmp_order_item = order_items.first
          quantity = order_items.sum { |order_item| order_item.quantity }
          amount = order_items.sum { |order_item| order_item.amount_in_cent }
          tmp_order_item.quantity = quantity
          tmp_order_item.amount_in_cent = amount
          @order_items_with_gifts << tmp_order_item
        end  
      end
      
      @order_items_with_gifts
    end

    def logistic_nos
      orders.map(&:logistic_nos).flatten.compact
    end

    def append(sale_order)
      self.transaction do
        if sale_order.warehouse_order_id.nil?
          sale_order.update!(warehouse_order_id: self.id)
          if !shopline?
            APPEND_FEILDS.each do |append_field|
              self[append_field] = [self[append_field], sale_order[append_field]].reject(&:blank?).join(";")
            end
          end

          self.save!
        end
      end
    end

    def sync_sale_orders!
      if may_sync?
        self.transaction do
          self.synced!
          child_orders.each do |o|
            if o.may_sync?
              o.sync!
            else
              self.errors.add(:base, "销售订单 #{o.no} 状态不能从 #{o.sync_status} 变更为 synced")
              raise ActiveRecord::Rollback
            end
          end
        end
      elsif synced?
        # 已经是 synced 状态，不需要处理
      else
        self.errors.add(:base, "状态不能从 #{sync_status} 变更为 synced")
      end
    end

    def update_synced_at_and_eta(arg_synced_at, arg_eta, arg_delivery_path)
      self.transaction do
        child_orders.each do |order|
          unless order.update(synced_at: arg_synced_at, eta: arg_eta, delivery_path: arg_delivery_path)
            self.errors.add(:base, "销售订单 #{order.no} 更新 synced_at/eta/delivery_path 失败，错误信息：#{order.errors.full_messages.join(',')}")
            raise ActiveRecord::Rollback
          end
        end
      end
    end

    def sellout_sale_orders!
      if may_sellout?
        self.transaction do
          self.sellout!
          child_orders.each do |o|
            if o.may_sellout?
              o.sellout!
            else
              self.errors.add(:base, "销售订单 #{o.no} 状态不能从 #{o.sync_status} 变更为 synced")
              raise ActiveRecord::Rollback
            end
          end
        end
      else
        self.errors.add(:base, "状态不能从 #{sync_status} 变更为 stockout")
      end
    end

    def deliver_and_generate_logistic(tracking_no, stockout_items, order_eta = nil, delivery_path = nil)
      if shopline?
        self.transaction do
          # shopline订单没合并，目前只有一个订单
          order = shopline_orders.first

          # 判断是否全退
          # shopline的order_items会包含bank surcharge, 它的sku值为nil，需要过滤掉
          if order.order_items.select {|order_item| order_item["sku"].present? }.sum {|item| item["fulfillable_quantity"]} == stockout_items.sum { |item| item["qty"] }
            if order.may_sellout?
              order.sellout!
              return
            else
              self.errors.add(:base, "销售订单 #{order.no} 状态不能从 #{order.sync_status} 变更为 stockout")
              raise ActiveRecord::Rollback
            end
          end
          
          order.shopline_deliver_and_refund(logistic_no: tracking_no, stockout_items: stockout_items)
        end
      else
        order_no_with_stockout_items = split_stockout_items(stockout_items)

        self.transaction do
          orders.each do |order|
            current_order_stockout_items = order_no_with_stockout_items[order.no] || []
            if current_order_stockout_items.sum { |item| item["qty"] } == order.total_quantity
              if order.may_sellout?
                order.sellout!
                next
              else
                self.errors.add(:base, "销售订单 #{order.no} 状态不能从 #{order.sync_status} 变更为 stockout")
                raise ActiveRecord::Rollback
              end
            end

            order.deliver_and_generate_logistic(tracking_no, stockout_items: current_order_stockout_items, order_eta: order_eta, delivery_path: delivery_path)
          end

          if orders.all? { |order| order.stockout? }
            self.sellout! if may_sellout?
          end
        end
      end
    end

    def split_stockout_items(stockout_items)
      order_with_stockout_items = ActiveSupport::HashWithIndifferentAccess.new
      stockout_items_copy = stockout_items.clone

      # 优先满足下单早的订单配送，所以订单先退款先从后晚下单的开始
      orders.order(created_at: :desc).each do |order|
        current_order_stockout_items = []

        stockout_items_copy.each do |stockout_item|
          next if stockout_item["qty"] <= 0

          order_item =
            if stockout_item["product_id"].present?
              order.order_items.find_by(stock_keeping_unit_id: stockout_item["product_id"])
            elsif stockout_item["sku"].present?
              order.order_items.joins(:stock_keeping_unit).find_by("stock_keeping_units.no = ?", stockout_item["sku"]&.strip)
            elsif stockout_item["barcode"].present?
              order.order_items.joins(:stock_keeping_unit).find_by("stock_keeping_units.barcode ILIKE ?", "%#{stockout_item["barcode"]&.strip}%")
            end

          next if order_item.nil?

          # 如果订单购买的商品数量大于等于缺货商品数量，则将缺货商品数量全部加入到当前订单的商品中
          if order_item.quantity >= stockout_item["qty"]
            current_order_stockout_items << {
              "product_id" => order_item.stock_keeping_unit_id,
              "qty" => stockout_item["qty"]
            }
            stockout_item["qty"] = 0
          else
            # 否则当前订单的该商品全部缺货，然后从缺货总数里扣减当前商品数量
            current_order_stockout_items << {
              "product_id" => order_item.stock_keeping_unit_id,
              "qty" => order_item.quantity
            }
            stockout_item["qty"] -= order_item.quantity
          end
        end
        order_with_stockout_items[order.no] = current_order_stockout_items
      end

      order_with_stockout_items
    end

    def satisfy_kuaima_delivery?
      orders.pluck(:express_carrier).compact.size == orders.size
    end

    def kuaima_delivery?
      express_carrier == MagicBean::Order::KUAIMA_COMPANY
    end

    def latest_order
      @latest_order ||= orders.order(created_at: :asc).first
    end

    def order_status
      # 同步用，shopline订单同步都设置为待发货
      if shopline?
        "wait_seller_send_goods"
      else
        latest_order&.status
      end
    end

    def order_total
      @order_total ||= if shopline?
        shopline_orders.last&.order_total
      else
        ActiveSupport::NumberHelper.number_to_currency(orders.sum(:payment_in_cent) / 100.0, format: "%n", delimiter: "")
      end
    end

    def paid_at
      if shopline?
        shopline_orders.last&.paid_at
      else
        latest_order&.paid_at
      end
    end

    def child_orders
      shopline? ? shopline_orders : orders
    end

    private

    def generate_order_no
      # 仓储订单号格式：W + 年月日时分秒毫秒 + 3位随机数，共 18 位数
      no_prefix = Rails.env.production? ? "W" : "SW"
      loop do
        self.no = no_prefix + Time.now.strftime("%Y%m%d%H%M%L") + rand.to_s[2..4]
        break unless self.class.exists?(no: no)
      end
    end
  end
end
