# frozen_string_literal: true

module Wms::API::Entities
  class Order < Model
    expose :no, documentation: { type: String, desc: "订单号" }
    expose :delivery_type, documentation: { type: String, desc: "配送方式" }
    expose :order_total, documentation: { type: BigDecimal, desc: "订单支付金额(元)" }
    expose :paid_at, documentation: { type: DateTime, desc: "支付时间" }
    expose :order_status, documentation: { type: String, desc: "订单状态" }

    # receiver info
    expose :receiver_email, as: :email, documentation: { type: String, desc: "收件人邮箱" }
    expose :receiver_tel_number, as: :phone, documentation: { type: String, desc: "收件人手机" }
    expose :receiver_first_name, as: :shipping_first_name, documentation: { type: String, desc: "first name" }
    expose :receiver_last_name, as: :shipping_last_name, documentation: { type: String, desc: "last name" }
    expose :shipping_address_1, documentation: { type: String, desc: "收货地址1" }
    expose :shipping_address_2, documentation: { type: String, desc: "收货地址2" }
    expose :shipping_address_3, documentation: { type: String, desc: "收货地址3" }
    expose :receiver_street, as: :shipping_street, documentation: { type: String, desc: "shipping street" }
    expose :receiver_street_number, as: :shipping_street_number, documentation: { type: String, desc: "shipping street number" }
    expose :receiver_unit_number, as: :shipping_unit_number, documentation: { type: String, desc: "shipping unit number" }
    expose :receiver_city_name, as: :shipping_city, documentation: { type: String, desc: "shipping city" }
    expose :receiver_province_name, as: :shipping_state, documentation: { type: String, desc: "shipping state" }
    expose :receiver_postal_code, as: :shipping_postcode, documentation: { type: String, desc: "shipping postcode" }

    expose :sync_status, documentation: { type: String, desc: "同步状态" }
    expose :logistic_nos, documentation: { type: String, desc: "物流单号" }
    expose :delivery_date, documentation: { type: String, desc: "配送日期, 格式: 2020-03-16" }
    expose :prefer_time, documentation: { type: String, desc: "配送时间段, 格式: 17:00-21:00" }
    expose :authority_to_leave, documentation: { type: Grape::API::Boolean, desc: "是否允许放门口（无人签收）" }
    expose :deliver_to_door, documentation: { type: Grape::API::Boolean, desc: "是否送货上门" }
    expose :buyer_message, as: :delivery_note, documentation: { type: String, desc: "买家备注" }
    expose :remark, as: :order_note, documentation: { type: String, desc: "卖家备注" }
    expose :channel, documentation: { type: String, desc: "订单平台：web、app、mini_program" }
    expose :express_carrier, documentation: { type: String, desc: "邮寄订单第三方派送" }
    expose :store, using: ::Wms::API::Entities::Store
    expose :order_items_with_gifts, as: :order_items, using: Wms::API::Entities::OrderItem, documentation: { is_array: true, desc: "商品项（含赠品）" }
  end
end
