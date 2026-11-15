# frozen_string_literal: true

module BeansAdmin::API::Entities
  class SimpleStockKeepingUnit < ::CommonEntities::Model
    expose :no, documentation: { type: String, desc: "货号" }
    expose :properties, documentation: { type: String, desc: "规格" }
    expose :quantity, documentation: { type: Integer, desc: "库存" }
    expose :weight_in_gram, documentation: { type: Integer, desc: "每件重量（单位：克）" }
    expose :cost_price_in_cent, documentation: { type: Integer, desc: "成本价" }
    expose :cost_price_in_yuan
    expose :price_in_cent, documentation: { type: Integer, desc: "价格" }
    expose :price_in_yuan
    expose :shopline_price_in_cent, documentation: { type: Integer, desc: "Shopline价格" }
    expose :shopline_price_in_yuan
    expose :ae_price_in_cent, documentation: { type: Integer, desc: "AE价格" }
    expose :ae_price_in_yuan
    expose :strikethrough_price_in_cent, documentation: { type: Integer, desc: "划线价" }
    expose :strikethrough_price_in_yuan
    expose :discount_quantity, documentation: { type: Integer, desc: "购买数量大于等于" }
    expose :discount_price_in_cent, documentation: { type: Integer, desc: "折扣价格" }
    expose :discount_price_in_yuan
    expose :strikethrough_price_in_yuan
    expose :cover, as: :image, documentation: { type: String, desc: "图片" }
    expose :comments_count
    expose :properties_array
    expose :properties_text
    expose :item_id
    expose :title
    expose :height_in_cm, documentation: { type: Float, desc: "高度" }
    expose :width_in_cm, documentation: { type: Float, desc: "宽度" }
    expose :length_in_cm, documentation: { type: Float, desc: "长度" }
    expose :barcode, documentation: { type: String, desc: "条形码" }
    expose :on_sale, documentation: { type: Grape::API::Boolean, desc: "是否上架" }
    expose :human_title
    expose :carton_size
    expose :custom_pending_in_stock_notices_count, as: :pending_in_stock_notices_count
    expose :gst_percent
    expose :marketing_mode
    expose :shoppingunit
    expose :is_special
    expose :is_private_kitchen
    expose :nominal_gross_margin_ratio
    expose :turnover_rate
    expose :first_sale_at, documentation: { type: DateTime, desc: "首次上架时间" }
    expose :is_box_regulation, documentation: { type: Grape::API::Boolean, desc: "是否箱规" }

    def custom_pending_in_stock_notices_count
      # 只有pending_notice_hash为nil才去读取sku表里面的pending_in_stock_notices_count
      if options[:pending_notice_hash]
        options[:pending_notice_hash][object.id].to_i
      else
        object.pending_in_stock_notices_count
      end
    end
  end
end
