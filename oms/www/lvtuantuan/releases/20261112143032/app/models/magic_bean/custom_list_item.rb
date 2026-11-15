# frozen_string_literal: true
module MagicBean
  class CustomListItem < ApplicationRecord
    belongs_to :item
    belongs_to :custom_list

    scope :on_sale, -> { includes([item: :on_sale_skus]).joins(:item).where("items.listing_type in (1,2) AND items.quantity > 0 AND items.gift_only = false").reorder(MagicBean::CustomList.item_default_order) }
    scope :not_merchant_delivery, -> { on_sale.where("'self_pick' = ANY(items.delivery_type) or 'express' = ANY(items.delivery_type) or 'virtual_delivery' = ANY(items.delivery_type)").reorder(MagicBean::CustomList.item_default_order) }
  end
end
