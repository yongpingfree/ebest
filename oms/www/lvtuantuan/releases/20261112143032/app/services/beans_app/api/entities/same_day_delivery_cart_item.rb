# frozen_string_literal: true

module BeansApp::API::Entities
  class SameDayDeliveryCartItem < ::CommonEntities::Model
    expose :quantity
    expose :stock_keeping_unit do |_, _|
      BeansApp::API::Entities::SimpleStockKeepingUnit.represent(object.stock_keeping_unit, item_quantity: object.quantity, pending_sku_ids: options[:pending_sku_ids], is_new_user: options[:is_new_user], active_top_left_item_hash: options[:active_top_left_item_hash])
    end
  end
end
