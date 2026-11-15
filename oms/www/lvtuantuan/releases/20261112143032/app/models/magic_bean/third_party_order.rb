# frozen_string_literal: true

class MagicBean::ThirdPartyOrder < ApplicationRecord
  include AASM

  enum third_party_type: { shopline: 1, aliexpress: 2 }

  # 同步 wms 状态
  enum sync_status: {
    pending: 1,    # 待管理员确认订单
    confirmed: 2,  # 待同步到 wms
    synced: 3,      # 已同步到 wms
    stockout: 4
  }

  enum delivery_type: {
    merchant_delivery: 1,
    self_pick: 2,
    express: 3
  }

  CUTOFF_TIME = "22:00" # 截单时间点 22时
  CONFIRM_ORDER_TIME_AFTER_CUTOFF_TIME = 17.minutes

  aasm :sync_status, column: :sync_status, enum: true, requires_lock: true do
    state :pending, initial: true
    state :confirmed
    state :synced
    state :stockout

    event :sync do
      transitions from: :confirmed, to: :synced
    end

    event :sellout do
      transitions from: [:confirmed, :synced],
                  to: :stockout,
                  success: [
                    :auto_full_refund
                  ]
    end
  end

  validates :third_party_id, presence: true, uniqueness: { scope: :third_party_type }

  belongs_to :store
  belongs_to :warehouse_order, optional: true
  has_many :operation_records, dependent: :destroy, as: :operatable

  delegate :no, to: :warehouse_order, prefix: true, allow_nil: true

  ransacker :sync_status, formatter: proc { |v| sync_statuses[v] }
  ransacker :delivery_type, formatter: proc { |v| delivery_types[v] }
  ransacker :third_party_type, formatter: proc { |v| third_party_types[v] }

  after_create :enqueue_set_order_confirmed_job, :decrease_inventory!, :send_order_paid_notice
  after_commit :enqueue_set_order_confirmed_job, if: :saved_change_to_delivery_date?, on: :update
  after_commit :update_order_metafields, if: :saved_change_to_delivery_date?

  delegate :name, to: :store, prefix: true
  delegate :peti_store?, to: :store

  def self.create_shopline_order(shopline_order_no, peti_store, store_site_config, source = "job")
    order = MagicBean::ThirdPartyOrder.find_by(no: shopline_order_no)

    if order.blank?
      # 查询订单数据
      response = Shopline::Api.get_orders(shopline_order_no, peti_store)
      # {"traceId":"a1aded8eed735275eb5ddc85ad5b6bd1","code":"B0000001","data":null,"success":false,"message":"The requested apiPath does not exist!","error":"The requested apiPath does not exist!"}
      # 出现了新错误，但没有errors字段
      error = response["errors"] || response["error"]
      raise error if error.present?

      res = response["orders"]&.first

      # 如果是job创建，则直接raise，admin则返回错误信息
      raise "订单为空" if res.blank? && source == "job"
      return ["请输入正确的未归档Shopline订单号"] if res.blank? && source == "admin"

      if res["service"]&.downcase == "pickup"
        delivery_type = "self_pick"
        receiver_properties = res["locations"].first
        receiver_properties["email"] = res["email"]
        receiver_properties["phone"] = res["phone"]
        # 自提订单没有first_name、last_name字段，用billing_address中的字段代替，但是这两个字段不一定有值
        # 使用折扣码付款的订单没有billing_address字段，这个场景用customer中的字段代替
        address = res["billing_address"] || res["customer"]
        receiver_properties["first_name"] = address&.dig("first_name")
        receiver_properties["last_name"] = address&.dig("last_name")
        prefer_time = "15:00-18:00"
      else
        # 判断shipping_lines是否包含了Aupost关键词，来确定是邮件还是自派
        if res["shipping_lines"].any? {|shipping_line| shipping_line["title"].include? "Aupost" }
          delivery_type = "express"
        else
          delivery_type = "merchant_delivery"
        end

        receiver_properties = res["shipping_address"]
        receiver_properties["email"] = res["email"]
        prefer_time = "10:00-23:00"
      end

      customer_id = res["customer"]["id"]
      
      # 当前时间如果超过截单时间，配送日期就选后天
      # 获取匹配中的截单时间
      time = Time.current
      selected_cot = store_site_config.format_cutoff_time.reject { |t| t[:time] <= time.strftime("%H:%M") }.first
      if selected_cot.blank?
        selected_cot = store_site_config.format_cutoff_time.first
        time += 1.day
      end

      delivery_date = ("#{time.strftime("%Y-%m-%d")} #{selected_cot[:time]}".in_time_zone + (selected_cot[:time_kind] == "next_day" ? 1 : 0).days).to_date
      # 周日不配送
      delivery_date += 1.day if delivery_date.wday == 0

      # 自派订单需要查配送时间管理里面的星期数
      if delivery_type.in? ["merchant_delivery", "self_pick"]
        delivery_time = if delivery_type == "merchant_delivery"
          delivery_area = MagicBean::DeliveryArea.ransack(postal_code_eq: receiver_properties["zip"]&.strip || -1, suburb_case_insensitive_eq: receiver_properties["city"]&.strip&.downcase || -1).result.first
          delivery_area&.delivery_time
        else
          MagicBean::SelfPickUp.ransack(postal_code_eq: receiver_properties["zip"]&.strip || -1, city_name_case_insensitive_eq: receiver_properties["city"]&.strip&.downcase || -1, store_id_eq: store_site_config.store_id || -1).result.first
        end

        if delivery_time && delivery_time.weekdays.present?
          limit = 0
          loop do
            wday = delivery_date.wday.to_s
            if wday.in?(delivery_time.weekdays) && !delivery_date.to_s.in?(MagicBean::Item::NOT_DELIVERY_DAYS)
              break
            else
              limit += 1
              delivery_date += 1.day
            end
            break if limit > 14
          end
        end
      end

      order = create!(
        sync_status: :pending,
        third_party_type: :shopline,
        third_party_id: res["name"],
        no: res["id"],
        customer_id: customer_id,
        status: res["status"],
        financial_status: res["financial_status"],
        fulfillment_status: res["fulfillment_status"],
        delivery_type: delivery_type,
        delivery_date: delivery_date.to_s,
        prefer_time: prefer_time,
        order_total: res["current_total_price"],
        total_discounts: res["total_discounts"],
        total_line_items_price: res["total_line_items_price"],
        order_items: res["line_items"],
        payment_details: res["payment_details"],
        receiver_properties: receiver_properties,
        buyer_message: res["buyer_note"],
        shipping_lines: res["shipping_lines"],
        store_id: store_site_config.store_id,
        refunds: res["refunds"]
      )
      ["success", order]
    else
      ["该订单已同步过，请输入其他订单号"]
    end
  end

  def order_store_time_zone
    @order_store_time_zone ||= store.current_time_zone
  end

  def warehouse_order_uniq_hash
    {
      sync_status: :confirmed,
      store_id: store_id,
      delivery_type: delivery_type,
      delivery_date: delivery_date,
      prefer_time: prefer_time,
      channel: third_party_type,
      receiver_properties: shopline_receiver_properties,
      deliver_to_door: false,
      authority_to_leave: false,
      buyer_message: buyer_message
    }
  end

  def can_create_warehouse_order?
    warehouse_order_id.nil? && confirmed? && financial_status == "paid" && delivery_date.present?
  end

  # 生成仓储订单，第三方的订单都不合并
  def generate_shopline_warehouse_order
    return unless can_create_warehouse_order?

    wo = MagicBean::WarehouseOrder.create(warehouse_order_uniq_hash)
    
    wo.append(self)
  end

  def paid_at
    if shopline?
      # 风险支付不做处理
      payment_details.select { |payment| payment["pay_status"].in? ["paid", "risking"] }.first&.dig("processed_at")&.in_time_zone
    end
  end

  def may_deliver?
    fulfillment_status == "null"
  end

  # stockout_items: [{"product_id"=>2254, "sku"=>"food01878", "qty"=>2}]
  def shopline_deliver_and_refund(logistic_no: nil, company: "eBest", stockout_items: [], full_refund: false)
    # 批量处理订单，如果有一个退款失败，会导致成功的重复退款，所以已经发货的要跳过退款
    return unless may_deliver?
    
    # shopline如果有退款，需要退款有结果才可以发货
    if full_refund || stockout_items.present?
      # shopline不支持测试环境退款
      return unless Rails.env.production?

      refund_result = shopline_refund(full_refund: full_refund, stockout_items: stockout_items)
      raise "shopline refund error: #{refund_result["errors"]}" if refund_result["errors"].present?
      return if full_refund
    end

    # 避免发货失败导致重复退款，发货用job异步处理
    DeliverShoplineOrderJob.perform_later(id, logistic_no, company)
  end

  def shopline_deliver(tracking_no, company = "eBest")
    return unless may_deliver?

    deliver_params = {
      "fulfillment": {
        "line_items": order_items.map do |item|
          next unless item["fulfillable_quantity"].positive?
          {
            "id": item["id"].to_i,
            "quantity": item["fulfillable_quantity"]
          }
        end.compact,
        notify_customer: false, # Shipment Status变动也会发邮件，所以传false就好
        tracking_company: company,
        tracking_number: tracking_no.presence || warehouse_order&.no, # 没有tracking_number用仓储单号
        tracking_url: delivery_track
      }
    }

    result = Shopline::Api.deliver(no, deliver_params, peti_store?)

    if result["errors"].blank?
      update(fulfillment_status: "fulfilled", tracking_no: tracking_no)
      send_order_deliver_notice
    else
      raise result["errors"]
    end
  end

  def refresh_shopline_order
     # shopline订单发货后就会归档，订单查询接口也会返回空数据，所以这里要判断fulfillment_status的值是否为null
    if may_deliver?
      res = Shopline::Api.get_orders(no, peti_store?)["orders"].first
      update(
        status: res["status"],
        financial_status: res["financial_status"],
        fulfillment_status: res["fulfillment_status"],
        order_items: res["line_items"],
        payment_details: res["payment_details"],
        refunds: res["refunds"]
      )
    end  
  end

  def decrease_inventory!
    self.transaction do
      order_items.each do |order_item|
        sku = MagicBean::StockKeepingUnit.find_by(no: order_item["sku"], store_id: store_id)
        sku&.decrease_inventory!([order_item["quantity"].to_i, sku.quantity].min)
      end
    end
  end

  def human_receiver_properties
    return nil if receiver_properties.nil?
    "#{receiver_properties["address"]} #{receiver_properties["city"]} #{receiver_properties["province"]} #{receiver_properties["zip"]} #{receiver_properties["first_name"]} #{receiver_properties["last_name"]} #{receiver_properties["phone"]}"
  end

  def receiver_name
    return nil if receiver_properties.nil?
    "#{receiver_properties["first_name"]} #{receiver_properties["last_name"]}"
  end

  # 仅已全部退款订单可手动点击退库存
  def can_return_inventory?
    shopline? && !inventory_returned && financial_status == "refunded"
  end

  def title
    no
  end

  private
  def shopline_receiver_properties
    if merchant_delivery? || express?
      # shopline没有street信息，先传空，staging测试同步再看
      {
        "type" => "Address",
        "email" => receiver_properties["email"],
        "street" => nil,
        "city_name" => receiver_properties["city"],
        "last_name" => receiver_properties["last_name"],
        "first_name" => receiver_properties["first_name"],
        "tel_number" => receiver_properties["phone"],
        "detail_info" => "#{receiver_properties["address2"]} #{receiver_properties["address1"]}".strip,
        "postal_code" => receiver_properties["zip"],
        "unit_number" => nil,
        "company_name" => receiver_properties["company"],
        "province_name" => receiver_properties["province"],
        "street_number" => nil,
        "pure_detail_info" => receiver_properties["address1"]
      }
    else
      {
        "type" => "SelfPickUp",
        "email" => receiver_properties["email"],
        "street" => nil,
        "city_name" => receiver_properties["city"],
        "last_name" => receiver_properties["last_name"],
        "first_name" => receiver_properties["first_name"],
        "tel_number" => receiver_properties["phone"],
        "detail_info" => receiver_properties["address"],
        "postal_code" => receiver_properties["zip"],
        "province_name" => receiver_properties["province"],
        "street_number" => nil
      }
    end
  end

  def enqueue_set_order_confirmed_job
    # 根据用户选的配送时间，提前一天自动确认
    cutoff_time = "#{delivery_date} #{current_store_cutoff_time_string}".in_time_zone(order_store_time_zone).yesterday
    confirm_time = cutoff_time + CONFIRM_ORDER_TIME_AFTER_CUTOFF_TIME

    SetThirdPartyOrderConfirmedJob.set(wait_until: confirm_time).perform_later(id, cutoff_time.to_date.to_s)
  end

  def current_store_site_config
    @current_store_site_config ||= store.site_config
  end

  def current_store_cutoff_time_string
    # 动态获取当前store配置的cutoff_time, 获取比较大的时间
    format_cutoff_time = current_store_site_config.format_cutoff_time.last
    format_cutoff_time.present? ? format_cutoff_time[:time] : CUTOFF_TIME
  end

  def freight_amount
    shipping_lines.first["price"]
  end

  def refunded_amount
    refunds.present? ? refunds.sum { |refund| refund["transactions"].select { |transaction| transaction["status"] == "success" }.first&.dig("amount").to_f } : 0
  end

  def auto_full_refund
    DeliverAndRefundShoplineOrderJob.perform_later(id, true)
  end

  def shopline_refund_calculate(full_refund: false, stockout_items: [])
    refund_line_items = if full_refund
      order_items.map do |item|
        {
          "line_item_id": item["id"].to_s,
          "quantity": item["fulfillable_quantity"],
          "type": "Unshipped"
        }
      end
    else
      items_hash = stockout_items_hash(stockout_items)
      order_items.select { |item| items_hash.keys.include?(item["sku"]) }.map do |item|
        {
          "line_item_id": item["id"].to_s,
          "quantity": items_hash["#{item["sku"]}"],
          "type": "Unshipped"
        }
      end
    end

    calculate_params = {
      "currency": "AUD",
      "refund_line_items": refund_line_items,
      "shipping": {
        "amount": (full_refund ? freight_amount : 0).to_s,
        "full_refund": full_refund
      }
    }

    result = Shopline::Api.refund_calculate(no, calculate_params, peti_store?)

    result["refund"]
  end

  def shopline_refund(full_refund: false, stockout_items: [])
    # 先计算可退金额
    refund_calculate = shopline_refund_calculate(full_refund: full_refund, stockout_items: stockout_items)

    # 商品都退款完，transactons会为空
    return {} if refund_calculate["transactons"].blank?

    transactions = refund_calculate["transactons"].map do |transaction|
      {
        "amount": transaction["amount"],
        "gateway": transaction["gateway"],
        "id": transaction["parent_id"],
        "currency": transaction["currency"],
        "kind": "refund",
        "type": true
      }
    end

    items_hash = stockout_items_hash(refund_calculate["refund_line_items"], "line_item_id")
    refund_line_items = order_items.select { |item| items_hash.keys.include?(item["id"]) }.map do |item|
      {
        "line_item_id": item["id"].to_i,
        "location_id": item["location_id"],
        "quantity": items_hash["#{item["id"]}"],
        "restock_type": "no_restock", # no_restock: 不回退库存
        "type": "Unshipped"
      }
    end

    refund_params = {
      "currency": "AUD",
      "note": "缺货退款",
      "notify": true,
      "order_id": no,
      "processed_at": Time.current.strftime("%Y-%m-%dT%H:%M:%S%z"),
      "refund_line_items": refund_line_items,
      "shipping": {
        "amount": refund_calculate["shipping"]["amount"],
        "full_refund": full_refund
      },
      "transactions": transactions
    }

    Shopline::Api.refund(refund_params, peti_store?)
  end

  def stockout_items_hash(stockout_items, target_key = "sku")
    item_hash = {}
    stockout_items.each do |item|
      item_hash["#{item[target_key]}"] = item["qty"] || item["quantity"]
    end
    item_hash
  end

  def send_order_paid_notice
    OrderMailer.with(order: self).shopline_order_paid.deliver_later unless Rails.env.development?
  end

  def send_order_deliver_notice
    OrderMailer.with(order: self).shopline_order_deliver.deliver_later unless Rails.env.development?
  end

  def update_order_metafields
    UpdateShoplineOrderMetafieldsJob.perform_later(no) if shopline?
  end
end
