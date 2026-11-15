# frozen_string_literal: true

class CheckItemTimeLimitedPromotionJob < ApplicationJob
  queue_as :default

  def perform
    in_time_limited_promotion_item_ids = []
    activate_promotion_item_ids = []

    activate_promotion_item_ids = MagicBean::TimeLimitedPromotion.active.includes([:stock_keeping_units]).map do |promotion|
      promotion.stock_keeping_units.map(&:item_id).uniq
    end.flatten.uniq

    MagicBean::Item.where(ae_drop_shipper: false).find_each do |item|
      in_time_limited_promotion_item_ids << item.id if item.in_time_limited_promotion?
    end

    MagicBean::Item.includes(:on_sale_skus).where(ae_drop_shipper: false, id: (in_time_limited_promotion_item_ids - activate_promotion_item_ids) + (activate_promotion_item_ids - in_time_limited_promotion_item_ids)).find_each do |item|
      item.update_in_time_limited_promotion_info
    end
  end
end
