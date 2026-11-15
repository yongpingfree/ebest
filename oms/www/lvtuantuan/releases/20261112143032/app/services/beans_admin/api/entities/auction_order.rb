# frozen_string_literal: true

module BeansAdmin::API::Entities
  class AuctionOrder < ::CommonEntities::Model
    expose :no
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
    expose :admin_refundable?, as: :refundable
    expose :properties_texts do |instance, _|
      instance.order_items.pluck(:properties_text)
    end
    expose :cost_integral
    expose :sync_status
    expose :wechat_payment_in_yuan
    expose :wechat_service_percentage
    expose :credit_card_payment_in_yuan
    expose :credit_card_service_percentage
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
    expose :human_receiver_properties
    expose :receiver_first_name
    expose :receiver_last_name
    expose :receiver_tel_number
    expose :receiver_email
    expose :order_items, using: BeansAdmin::API::Entities::OrderItem, documentation: { is_array: true }
    expose :gift_card_amount_in_cent
    expose :gift_card_amount_in_yuan
    expose :coupon, using: BeansAdmin::API::Entities::Coupon
    expose :transaction_id
    expose :try_payment_times
    expose :payment_channel
    expose :store_name

    def payment_channel
      options[:payment_channels].nil? ? object.completed_charge_payment&.channel : options[:payment_channels][object.id]
    end
  end
end
