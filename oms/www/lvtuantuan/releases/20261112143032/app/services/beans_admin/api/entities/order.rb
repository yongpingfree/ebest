# frozen_string_literal: true

module BeansAdmin::API::Entities
  class Order < SimpleOrder
    expose :transaction_id
    expose :estimated_settled_time_of_integral
    expose :refund_no
    expose :prepay_id
    expose :human_gift_coupons
    expose :order_items, using: BeansAdmin::API::Entities::OrderItem, documentation: { is_array: true }
    expose :ae_drop_shipper_orders, using: BeansAdmin::API::Entities::AeDropShipperOrder, documentation: { is_array: true }
    expose :scene_code do |instance, _|
      Wechat::SceneCode.info(instance.scene_code)
    end
    expose :order_invoice, using: SimpleOrderInvoice
    expose :order_invoice_present do |instance, _|
      instance.order_invoice.present?
    end
    expose :after_sale_reasons

    def after_sale_reasons
      MagicBean::MultiLangConfig.find_by(key: "after_sale_reasons", kind: :app)&.value&.split(/[;；]/)
    end
  end
end
