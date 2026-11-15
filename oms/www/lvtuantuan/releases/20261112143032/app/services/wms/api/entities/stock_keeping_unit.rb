# frozen_string_literal: true

module Wms::API::Entities
  class StockKeepingUnit < Model
    expose :properties_text, as: :product_name, documentation: { type: String, desc: "商品名称" }
    expose :cover, as: :product_image, documentation: { type: String, desc: "商品图片" }
    expose :brand_name, as: :brand, documentation: { type: String, desc: "商品品牌" }
    expose :title_zh_cn, as: :title_cn, documentation: { type: String, desc: "产品标题" }
    expose :title_en, documentation: { type: String, desc: "产品标题(en)" }
    expose :short_title, documentation: { type: String, desc: "产品短标题" }
    expose :barcode, as: :barcode, documentation: { type: String, desc: "barcode" }
    expose :weight_in_gram, as: :weight, documentation: { type: BigDecimal, desc: "重量" }
    expose :height_in_cm, as: :height, documentation: { type: Float, desc: "高度(cm)" }
    expose :length_in_cm, as: :length, documentation: { type: Float, desc: "长度(cm)" }
    expose :width_in_cm, as: :width, documentation: { type: Float, desc: "宽度(cm)" }
    expose :price_in_yuan, as: :unit_price, documentation: { type: BigDecimal, desc: "价格(元)" }
    expose :no, as: :sku,  documentation: { type: String, desc: "SKU" }
    expose :category_id
    expose :category_name
    expose :parent_category_id
    expose :parent_category_name
    expose :carton_size
    expose :is_on_sale?, as: :on_sale, documentation: { type: Grape::API::Boolean, desc: "上架 / 下架" }
    expose :store, using: ::Wms::API::Entities::Store
    expose :gst_percent
    expose :marketing_mode
    expose :shoppingunit
    expose :is_special
    expose :can_cover_weeks
    expose :leader, documentation: { type: String, desc: "负责人" }
    expose :storage_method, documentation: { type: String, desc: "存储方式" }
  end
end
