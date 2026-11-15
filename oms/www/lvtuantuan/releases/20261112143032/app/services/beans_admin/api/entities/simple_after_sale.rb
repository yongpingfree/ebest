# frozen_string_literal: true

module BeansAdmin::API::Entities
  class SimpleAfterSale < ::CommonEntities::Model
    expose :refund_no
    expose :after_sale_type, documentation: { type: String, desc: "售后类型" }
    expose :return_type, documentation: { type: String, desc: "退款类型" }
    expose :applicant_type, documentation: { type: String, desc: "发起人类型" }
    expose :reason, documentation: { desc: "退货、退款原因" }
    expose :additional_information, documentation: { desc: "补充说明" }
    expose :total_quantity, documentation: { type: Integer, desc: "退款货物总件数" }
    expose :logistic_no, documentation: { desc: "退货物流单号" }
    expose :logistic_company, documentation: { desc: "退货物流公司" }
    expose :status, documentation: { desc: "状态" }
    expose :order_no, documentation: { desc: "订单号" }
    expose :order_id
    expose :order_type
    expose :amount_in_yuan
    expose :original_amount_in_cent
    expose :original_amount_in_yuan
    expose :custom_nickname, as: :user_nickname
    expose :agreed_at
    expose :order_freight_in_yuan
    expose :order_payment_in_yuan
    expose :can_show_confirm?, as: :can_show_confirm
    expose :return_integral_amount
    expose :order_aud_to_cny_exchange_rate
    expose :order_wechat_service_percentage
    expose :order_payment_in_yuan
    expose :order_payment_type
    expose :order_wechat_payment_in_yuan
    expose :order_credit_card_service_percentage
    expose :order_credit_card_payment_in_yuan
    expose :order_credit_card_service_amount_in_yuan
    expose :order_omipay_service_amount_dollar_in_yuan
    expose :order_omipay_payment_dollar_in_yuan
    expose :order_omipay_payment_in_yuan
    expose :order_supay_service_amount_dollar_in_yuan
    expose :order_supay_payment_dollar_in_yuan
    expose :order_supay_payment_in_yuan
    expose :return_gift_card_amount_in_cent
    expose :return_gift_card_amount_in_yuan
    expose :return_coupon_amount_in_cent
    expose :return_coupon_amount_in_yuan
    expose :after_sales_order_items, with: BeansAdmin::API::Entities::AfterSalesOrderItem, documentation: { is_array: true }
    expose :internal_reason
    expose :department
    expose :audit_explain
    expose :audit_video
    expose :audit_images
    expose :is_real_claim
    expose :lastest_operator, with: BeansAdmin::API::Entities::MinimalAdminUser, documentation: { type: String, desc: "最后操作人" }

    def custom_nickname
      object.user_origin_nickname.presence || object.user_nickname
    end
  end
end
