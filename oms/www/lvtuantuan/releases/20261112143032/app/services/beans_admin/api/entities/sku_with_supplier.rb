# frozen_string_literal: true

module BeansAdmin::API::Entities
  class SkuWithSupplier < SimpleStockKeepingUnit
    expose :parent_category_name
    expose :category_name
    expose :category_id
    expose :newest_supplier_cost_in_yuan
    expose :newest_supplier_name
    expose :listing_type
    expose :newest_supplier_include_gst
    expose :newest_supplier_gst_amount
  end
end
