# frozen_string_literal: true

module BeansApp::API::Entities
  # 购物项使用 StockKeepingUnitDetail, 直接继承 SimpleStockKeepingUnit
  # 因为不需要 StockKeepingUnit 中的 current_sku_groupon
  class SimpleStockKeepingUnit < MinimalStockKeepingUnit
    expose :custom_properties_text, as: :properties_text

    def custom_properties_text
      (options[:item] || object.item).ae_drop_shipper ? object.ae_drop_shipper_properties_text : object.properties_text
    end
  end
end
