# frozen_string_literal: true

module MagicBean
  class PaymentSetting < ApplicationRecord
    include PriceConvertConcern

    # scope

    # constants

    # attr related macros
    convert_price_to_yuan :no_transaction_fee_over_amount_in_cent

    # association macros
    belongs_to :store
    has_many :operation_records, dependent: :destroy, as: :operatable

    # validation macros
    # omipay手续费只能非负数，因为小程序全部用的omipay
    validates :omipay_wechat_service_percentage, :omipay_alipay_service_percentage, numericality: { greater_than_or_equal_to: 0, message: "不能为负数" }
    validates :no_transaction_fee_over_amount_in_cent , numericality: { greater_than: 0, message: "必须为正数" }, allow_nil: true
    validates :wechat_service_percentage, :vm_credit_card_service_percentage, :unionpay_credit_card_service_percentage,
              :exchange_rate_rise_percentage, :supay_wechat_service_percentage, :supay_alipay_service_percentage,
              :apple_pay_service_percentage, :cba_apple_pay_service_percentage, :cba_google_pay_service_percentage,
              presence: true
  end
end
