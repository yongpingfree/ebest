# frozen_string_literal: true

module BeansApp::API::Entities
  class AfterSale < ::CommonEntities::Model
    expose :order_no
    expose :refund_no
    expose :order_id, documentation: { type: Integer, desc: "订单ID" }
    expose :after_sale_type, documentation: { type: String, desc: "售后类型" }
    expose :reason, documentation: { desc: "退货、退款原因" }
    expose :additional_information, documentation: { desc: "补充说明" }
    expose :images, documentation: { type: String, is_array: true, desc: "图片" }
    expose :total_quantity, documentation: { type: Integer, desc: "退款货物总件数" }
    expose :amount_in_cent
    expose :amount_in_yuan
    expose :original_amount_in_cent
    expose :original_amount_in_yuan
    expose :logistic_no, documentation: { desc: "退货物流单号" }
    expose :logistic_company, documentation: { desc: "退货物流公司" }
    expose :status, documentation: { desc: "售后状态" }
    expose :seller_reply, documentation: { desc: "审核说明" }
    expose :agreed_at, documentation: { desc: "同意退货、款审核时间" }
    expose :after_sales_order_items, using: BeansApp::API::Entities::AfterSalesOrderItem
    expose :order, using: BeansApp::API::Entities::Order, documentation: { type: BeansApp::API::Entities::Order }, if: lambda { |_, options| options[:with_order] }
    expose :return_receiver_properties, if: lambda { |instance, _| instance.sale_return? }
    expose :order_total_payment_in_cent
    expose :return_integral_amount
    expose :return_gift_card_amount_in_cent
    expose :return_gift_card_amount_in_yuan
    expose :return_coupon_amount_in_cent
    expose :return_coupon_amount_in_yuan
    expose :wechat_amount_in_yuan
    expose :store, using: BeansApp::API::Entities::Store

    def return_receiver_properties
      MagicBean::SiteConfig.default_config&.return_receiver_properties
    end
  end
end
