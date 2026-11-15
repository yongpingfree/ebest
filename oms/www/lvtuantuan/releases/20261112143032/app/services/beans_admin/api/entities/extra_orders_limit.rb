# frozen_string_literal: true

module BeansAdmin::API::Entities
  class ExtraOrdersLimit < ::CommonEntities::Model
    expose :order_amount_in_yuan, documentation: { type: BigDecimal, desc: "满X金额" }
    expose :order_amount_in_cent, documentation: { type: Integer, desc: "满X金额" }
    expose :delivery_date, documentation: { desc: "配送日期" }
    expose :begin_at, documentation: { desc: "开始时间" }
    expose :extra_merchant_delivery_orders_limit, documentation: { type: Integer, desc: "额外自派配送地址数" }
    expose :extra_merchant_delivery_total_orders_limit, documentation: { type: Integer, desc: "额外自派配送订单数" }
  end
end
