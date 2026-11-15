# frozen_string_literal: true

module BeansAdmin::API::Entities
  class SimpleOrderItem < ::CommonEntities::Model
    expose :quantity
    expose :image
    expose :price_in_yuan
    expose :service_amount_in_cent
    expose :service_amount_in_yuan
    expose :gift_card_amount_in_cent
    expose :gift_card_amount_in_yuan
    expose :cash_amount_in_cent
    expose :cash_amount_in_yuan
    expose :cost_integral
    expose :sku_human_title
    expose :properties_text
    expose :title
    expose :amount_in_yuan
    expose :real_price_in_yuan
    expose :item_id
    expose :groups
    expose :stock_keeping_unit_id
    expose :gst_percent
    expose :gst_amount_in_cent
    expose :gst_amount_in_yuan
    expose :marketing_mode
    expose :storage_method
    expose :ae_gst_amount_in_cent
    expose :ae_gst_amount_in_yuan
  end
end
