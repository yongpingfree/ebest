# frozen_string_literal: true

module BeansApp::API::Entities
  class SimpleOrder < ::CommonEntities::Model
    expose :no
    expose :type
    expose :ae_drop_shipper
    expose :is_child, documentation: { desc: "是否加单的子单" }
    expose :payment_in_cent, documentation: { type: Integer, desc: "实付金额（单位：分）" }
    expose :amount_in_cent, documentation: { type: Integer, desc: "订单金额，未计算优惠之前的原价格（单位：分）" }
    expose :freight_in_cent, documentation: { type: Integer, desc: "运费（单位：分）" }
    expose :original_payment_in_cent, documentation: { type: Integer, desc: "订单金额 + 运费（单位：分）" }
    expose :total_payment_in_cent, documentation: { type: Integer, desc: "优惠后的金额，包含积分（单位：分）" }
    expose :payment_in_yuan
    expose :payment_without_gift_card_in_cent
    expose :payment_without_gift_card_in_yuan
    expose :final_amount_without_gift_card_in_cent
    expose :final_amount_without_gift_card_in_yuan
    expose :final_amount_with_gift_card_in_cent
    expose :final_amount_with_gift_card_in_yuan
    expose :final_amount_in_cent
    expose :final_amount_in_yuan
    expose :amount_in_yuan
    expose :freight_in_yuan
    expose :original_payment_in_yuan
    expose :total_payment_in_yuan
    expose :ae_gst_amount_in_yuan
    expose :status
    expose :quantity
    expose :order_items, using: SimpleOrderItem
    expose :after_sales_creatable?, as: :after_sales_creatable
    expose :commentable?, as: :commentable
    expose :after_sales_count
    expose :refundable?, as: :refundable
    expose :gift_card_amount_in_cent
    expose :gift_card_amount_in_yuan
    expose :cost_integral
    expose :cost_integral_amount_in_yuan
    expose :cost_integral_amount_in_cent
    expose :integral_deducted_from_one_yuan
    expose :delivery_type
    expose :delivery_path
    expose :wechat_payment_in_yuan
    expose :wechat_service_amount_in_yuan
    expose :wechat_service_percentage
    expose :omipay_wechat_service_percentage
    expose :omipay_alipay_service_percentage
    expose :omipay_wechat_payment_dollar_in_yuan
    expose :omipay_wechat_payment_in_yuan
    expose :omipay_alipay_payment_dollar_in_yuan
    expose :omipay_alipay_payment_in_yuan
    expose :omipay_payment_dollar_in_yuan
    expose :omipay_payment_in_yuan
    expose :omipay_service_amount_dollar_in_yuan
    expose :omipay_service_amount_in_yuan
    expose :supay_wechat_service_percentage
    expose :supay_alipay_service_percentage
    expose :supay_wechat_payment_dollar_in_yuan
    expose :supay_wechat_payment_in_yuan
    expose :supay_alipay_payment_dollar_in_yuan
    expose :supay_alipay_payment_in_yuan
    expose :supay_payment_dollar_in_yuan
    expose :supay_payment_in_yuan
    expose :supay_service_amount_dollar_in_yuan
    expose :supay_service_amount_in_yuan
    expose :credit_card_payment_in_yuan
    expose :credit_card_service_amount_in_yuan
    expose :vm_credit_card_payment_in_yuan
    expose :unionpay_credit_card_payment_in_yuan
    expose :apple_pay_payment_in_yuan
    expose :cba_apple_pay_payment_in_yuan
    expose :cba_google_pay_payment_in_yuan
    expose :stripe_credit_card_payment_in_yuan
    expose :stripe_apple_pay_payment_in_yuan
    expose :stripe_google_pay_payment_in_yuan
    expose :credit_card_service_percentage
    expose :vm_credit_card_service_percentage
    expose :unionpay_credit_card_service_percentage
    expose :apple_pay_service_percentage
    expose :cba_apple_pay_service_percentage
    expose :cba_google_pay_service_percentage
    expose :stripe_credit_card_service_percentage
    expose :stripe_apple_pay_service_percentage
    expose :stripe_google_pay_service_percentage
    expose :display_omipay_wechat_service_amount_dollar_in_yuan
    expose :display_omipay_alipay_service_amount_dollar_in_yuan
    expose :display_supay_alipay_service_amount_dollar_in_yuan
    expose :display_supay_wechat_service_amount_dollar_in_yuan
    expose :display_vm_credit_card_service_amount_in_yuan
    expose :display_unionpay_credit_card_service_amount_in_yuan
    expose :display_apple_pay_service_amount_in_yuan
    expose :display_cba_apple_pay_service_amount_in_yuan
    expose :display_cba_google_pay_service_amount_in_yuan
    expose :display_stripe_credit_card_service_amount_in_yuan
    expose :display_stripe_apple_pay_service_amount_in_yuan
    expose :display_stripe_google_pay_service_amount_in_yuan    
    expose :display_cba_credit_card_service
    expose :display_unionpay_credit_card_service
    expose :display_omipay_wechat_service
    expose :display_omipay_alipay_service
    expose :display_supay_wechat_service
    expose :display_supay_alipay_service
    expose :display_apple_pay_service
    expose :display_cba_apple_pay_service
    expose :display_cba_google_pay_service
    expose :display_stripe_credit_card_service
    expose :display_stripe_apple_pay_service
    expose :display_stripe_google_pay_service
    expose :omipay_wechat_service_note
    expose :omipay_alipay_service_note
    expose :supay_wechat_service_note
    expose :supay_alipay_service_note
    expose :vm_credit_card_service_note
    expose :unionpay_credit_card_service_note
    expose :apple_pay_service_note
    expose :cba_apple_pay_service_note
    expose :cba_google_pay_service_note
    expose :stripe_credit_card_service_note
    expose :stripe_apple_pay_service_note
    expose :stripe_google_pay_service_note
    expose :enable_commweb_3ds_auth
    expose :wechat_note
    expose :omipay_wechat_note
    expose :aud_to_cny_exchange_rate
    expose :wechat_payment_dollar_in_yuan
    expose :payment_type
    expose :total_discount_amount_in_yuan
    expose :actually_order_items_amount_in_yuan
    expose :discount_amount_in_yuan
    expose :delivery_date
    expose :prefer_time
    expose :authority_to_leave
    expose :deliver_to_door
    expose :deliver_to_door_service_fee_in_cent
    expose :deliver_to_door_service_fee_in_yuan
    expose :channel
    expose :delivery_track
    expose :gifts_properties
    expose :custom_pool_gifts_properties, as: :pool_gifts_properties
    expose :pool_coupon_template_properties
    expose :active_pools
    expose :store, using: BeansApp::API::Entities::Store
    expose :order_invoice, using: BeansApp::API::Entities::OrderInvoice
    expose :gift_coupon_template, using: BeansApp::API::Entities::CouponTemplate
    expose :delivery_time_id
    expose :delivery_time_period_setting_id
    expose :original_freight_in_yuan
    expose :original_freight_total_in_yuan
    expose :box_regulation_fee_in_yuan
    expose :box_regulation_quantity
    expose :free_box_regulation_quantity
    expose :per_box_charge_in_yuan
    expose :time_period_fee_in_yuan
    expose :long_distance_fee_in_yuan
    expose :package_service_fee_in_yuan
    expose :package_service_discount_in_yuan
    expose :original_package_service_fee_in_yuan
    expose :value_added_service_fee_in_yuan
    expose :address_housing_type

    def custom_pool_gifts_properties
      object.pool_gifts_properties || []
    end

    def display_omipay_wechat_service_amount_dollar_in_yuan
      object.omipay_wechat_service_amount_dollar_in_cent.positive? ? object.omipay_wechat_service_amount_dollar_in_yuan : 0
    end

    def omipay_wechat_service_note
      I18n.t("grape.orders.service_text", amount: display_omipay_wechat_service_amount_dollar_in_yuan)
    end

    def display_omipay_alipay_service_amount_dollar_in_yuan
      object.omipay_alipay_service_amount_dollar_in_cent.positive? ? object.omipay_alipay_service_amount_dollar_in_yuan : 0
    end

    def omipay_alipay_service_note
      I18n.t("grape.orders.service_text", amount: display_omipay_alipay_service_amount_dollar_in_yuan)
    end

    def display_supay_wechat_service_amount_dollar_in_yuan
      object.supay_wechat_service_amount_dollar_in_cent.positive? ? object.supay_wechat_service_amount_dollar_in_yuan : 0
    end

    def supay_wechat_service_note
      I18n.t("grape.orders.service_text", amount: display_supay_wechat_service_amount_dollar_in_yuan)
    end

    def display_supay_alipay_service_amount_dollar_in_yuan
      object.supay_alipay_service_amount_dollar_in_cent.positive? ? object.supay_alipay_service_amount_dollar_in_yuan : 0
    end

    def supay_alipay_service_note
      I18n.t("grape.orders.service_text", amount: display_supay_alipay_service_amount_dollar_in_yuan)
    end

    def display_vm_credit_card_service_amount_in_yuan
      object.vm_credit_card_service_amount_in_cent.positive? ? object.vm_credit_card_service_amount_in_yuan : 0
    end

    def vm_credit_card_service_note
      I18n.t("grape.orders.service_text", amount: display_vm_credit_card_service_amount_in_yuan)
    end

    def display_unionpay_credit_card_service_amount_in_yuan
      object.unionpay_credit_card_service_amount_in_cent.positive? ? object.unionpay_credit_card_service_amount_in_yuan : 0
    end

    def unionpay_credit_card_service_note
      I18n.t("grape.orders.service_text", amount: display_unionpay_credit_card_service_amount_in_yuan)
    end

    def display_apple_pay_service_amount_in_yuan
      object.apple_pay_service_amount_in_cent.positive? ? object.apple_pay_service_amount_in_yuan : 0
    end

    def apple_pay_service_note
      I18n.t("grape.orders.service_text", amount: display_apple_pay_service_amount_in_yuan)
    end

    def display_cba_apple_pay_service_amount_in_yuan
      object.cba_apple_pay_service_amount_in_cent.positive? ? object.cba_apple_pay_service_amount_in_yuan : 0
    end

    def cba_apple_pay_service_note
      I18n.t("grape.orders.service_text", amount: display_cba_apple_pay_service_amount_in_yuan)
    end

    def display_cba_google_pay_service_amount_in_yuan
      object.cba_google_pay_service_amount_in_cent.positive? ? object.cba_google_pay_service_amount_in_yuan : 0
    end

    def cba_google_pay_service_note
      I18n.t("grape.orders.service_text", amount: display_cba_google_pay_service_amount_in_yuan)
    end

    def display_stripe_credit_card_service_amount_in_yuan
      object.stripe_credit_card_service_amount_in_cent.positive? ? object.stripe_credit_card_service_amount_in_yuan : 0
    end

    def stripe_credit_card_service_note
      I18n.t("grape.orders.service_text", amount: display_stripe_credit_card_service_amount_in_yuan)
    end

    def display_stripe_apple_pay_service_amount_in_yuan
      object.stripe_apple_pay_service_amount_in_cent.positive? ? object.stripe_apple_pay_service_amount_in_yuan : 0
    end

    def stripe_apple_pay_service_note
      I18n.t("grape.orders.service_text", amount: display_stripe_apple_pay_service_amount_in_yuan)
    end

    def display_stripe_google_pay_service_amount_in_yuan
      object.stripe_google_pay_service_amount_in_cent.positive? ? object.stripe_google_pay_service_amount_in_yuan : 0
    end

    def stripe_google_pay_service_note
      I18n.t("grape.orders.service_text", amount: display_stripe_google_pay_service_amount_in_yuan)
    end
  end
end
