# frozen_string_literal: true

module BeansAdmin::API::Entities
  class SimpleOrder < ::CommonEntities::Model
    expose :no
    expose :warehouse_order_no
    expose :type
    expose :is_child, documentation: { desc: "是否加单的子单" }
    expose :amount_in_cent
    expose :payment_in_cent
    expose :actually_amount_in_cent
    expose :amount_in_yuan
    expose :payment_in_yuan
    expose :total_payment_in_yuan
    expose :actually_amount_in_yuan
    expose :buyer_message
    expose :status
    expose :quantity
    expose :paid_at
    expose :remark
    expose :after_sales_count
    expose :after_sales_creatable?, as: :after_sales_creatable
    expose :user, using: BeansAdmin::API::Entities::SimpleUser
    expose :is_sent_but_status_not_show
    expose :apply_reason
    expose :can_show_fake_deliver?, as: :can_show_fake_deliver
    expose :admin_refundable?, as: :refundable
    expose :properties_texts do |instance, _|
      instance.order_items.pluck(:properties_text)
    end
    expose :logistics_present do |instance, _|
      instance.logistics.present?
    end
    expose :cost_integral
    expose :delivery_type
    expose :sync_status
    expose :wechat_payment_in_yuan
    expose :wechat_service_percentage
    expose :credit_card_payment_in_yuan
    expose :credit_card_service_percentage
    expose :credit_card_service_amount_in_yuan
    expose :aud_to_cny_exchange_rate
    expose :wechat_payment_dollar_in_yuan
    expose :omipay_service_amount_dollar_in_yuan
    expose :omipay_service_amount_in_yuan
    expose :omipay_payment_dollar_in_yuan
    expose :omipay_payment_in_yuan
    expose :supay_service_amount_dollar_in_yuan
    expose :supay_service_amount_in_yuan
    expose :supay_payment_dollar_in_yuan
    expose :supay_payment_in_yuan
    expose :payment_type
    expose :discount_amount_in_yuan
    expose :channel
    expose :synced_at
    expose :confirmed_at
    expose :human_receiver_properties
    expose :receiver_first_name
    expose :receiver_last_name
    expose :receiver_tel_number
    expose :receiver_unit_number
    expose :receiver_street_number
    expose :receiver_street
    expose :receiver_city_name
    expose :receiver_province_name
    expose :receiver_postal_code
    expose :address_housing_type
    expose :authority_to_leave
    expose :deliver_to_door
    expose :deliver_to_door_service_fee_in_cent
    expose :deliver_to_door_service_fee_in_yuan
    expose :delivery_date
    expose :prefer_time
    expose :delivered_at
    expose :delivery_track
    expose :order_items, using: BeansAdmin::API::Entities::SimpleOrderItem, documentation: { is_array: true }
    expose :gift_card_amount_in_cent
    expose :gift_card_amount_in_yuan
    expose :next_day_delivery
    expose :try_payment_times
    expose :payment_channel
    expose :same_day_delivery
    expose :human_gifts_properties
    expose :human_pool_gifts_properties
    expose :coupon, using: BeansAdmin::API::Entities::SimpleCoupon
    expose :store_name
    expose :cancel_reason
    expose :confirmed_at
    expose :freight_in_yuan
    expose :original_payment_in_yuan
    expose :freight_cost_in_yuan
    expose :freight_remark
    expose :finished_at
    expose :express_carrier
    expose :order_invoice, using: SimpleOrderInvoice
    expose :order_invoice_present do |instance, _|
      instance.order_invoice.present?
    end
    expose :can_create_warehouse_order?, as: :can_create_warehouse_order
    expose :delivery_path
    expose :ae_drop_shipper
    expose :ae_gst_amount_in_cent
    expose :ae_gst_amount_in_yuan
    expose :delivery_time_id
    expose :delivery_time_period_setting_id
    expose :box_regulation_fee_in_yuan
    expose :time_period_fee_in_yuan
    expose :long_distance_fee_in_yuan

    def payment_channel
      options[:payment_channels].nil? ? object.completed_charge_payment&.channel : options[:payment_channels][object.id]
    end

    def same_day_delivery
      object.type == "MagicBean::SameDayDeliveryOrder"
    end
  end
end
