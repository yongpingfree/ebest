# frozen_string_literal: true

module BeansAdmin::API::Entities
  class SkuSalePlan < ::CommonEntities::Model
    expose :item_id
    expose :title
    expose :no
    expose :brand_name
    expose :human_title
    expose :parent_category_name
    expose :category_name
    expose :category_id
    expose :listing_type
    expose :barcode
    expose :on_sale
    expose :price_in_yuan
    expose :quantity
    expose :reserved_quantity
    expose :carton_size
    expose :newest_supplier_name
    expose :newest_supplier_cost_in_yuan
    expose :gmv_sku_level
    expose :gp_sku_level
    expose :shoppingunit

    with_options(format_with: :integer) do
      expose :sales_count
    end

    expose :avg_sales_count
    expose :recommended_restocking_point_count, documentation: { desc: "建议补货数量" }
    expose :recommended_restocking_upper_limit_count, documentation: { desc: "建议补货上限数量" }
    expose :recommended_restocking_count, documentation: { desc: "建议补货数量" }

    # 日均销量，如果还没记录，日均销量设置为空
    def avg_sales_count
      sku_valid_inventory_dates_count = options[:sku_valid_inventory_dates_hash][object.id]
      (object.sales_count / sku_valid_inventory_dates_count.to_f).round(2) if sku_valid_inventory_dates_count
    end

    # 建議補貨點計算方式為：X * 日均銷量
    def recommended_restocking_point_count
      options[:recommended_restocking_point] * avg_sales_count if avg_sales_count
    end

    # 建議補貨上限計算方式為：Y * 日均銷量
    def recommended_restocking_upper_limit_count
      options[:recommended_restocking_upper_limit] * avg_sales_count if avg_sales_count
    end

    # 建議補貨數量計算方式為：建議補貨上限 - 當前可用庫存 (包括原價預留庫存)
    def recommended_restocking_count
      recommended_restocking_upper_limit_count - object.quantity - reserved_quantity if recommended_restocking_upper_limit_count
    end

    def reserved_quantity
      options[:reserved_quantity_hash][object.id].to_i
    end
  end
end
