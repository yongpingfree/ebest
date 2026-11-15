# frozen_string_literal: true

module Wms::API::Entities
  class OrderItem < Model
    expose :stock_keeping_unit_id , as: :product_id, documentation: { type: Integer, desc: "商品 ID" }
    expose :stock_keeping_unit_no, as: :sku, documentation: { type: String, desc: "SKU" }
    expose :properties_text, as: :product_name, documentation: { type: String, desc: "商品名称" }
    expose :brand_name, as: :brand, documentation: { type: String, desc: "商品品牌" }
    expose :title, as: :title_cn, documentation: { type: String, desc: "产品标题" }
    expose :sub_title, as: :title_en, documentation: { type: String, desc: "产品标题(en)" }
    expose :short_title, documentation: { type: String, desc: "产品短标题" }
    expose :barcode, as: :barcode, documentation: { type: String, desc: "barcode" }
    expose :weight_in_gram, as: :weight, documentation: { type: BigDecimal, desc: "重量" }
    expose :height_in_cm, as: :height, documentation: { type: Float, desc: "高度(cm)" }
    expose :length_in_cm, as: :length, documentation: { type: Float, desc: "长度(cm)" }
    expose :width_in_cm, as: :width, documentation: { type: Float, desc: "宽度(cm)" }
    expose :quantity, as: :qty, documentation: { type: Integer, desc: "数量" }
    expose :price_in_yuan, as: :unit_price, documentation: { type: BigDecimal, desc: "价格(元)" }
    expose :amount_in_yuan, as: :subtotal, documentation: { type: BigDecimal, desc: "总价格(元)" }
    expose :gst_amount_in_yuan
    expose :is_gift do |object|
      if object[:is_gift].nil?
        object.is_gift || false
      else
        object[:is_gift]
      end
    end
    expose :packing_instruction_type
    expose :packing_instruction
  end
end
