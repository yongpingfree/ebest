# frozen_string_literal: true
module BeansAdmin::API::Entities
  class TimeLimitedPromotionPrice < ::CommonEntities::Model
    expose :price_in_cent
    expose :price_in_yuan
    expose :stock_keeping_unit_id
    expose :stock_keeping_unit_human_title
    expose :stock_keeping_unit_no
    expose :stock_keeping_unit_barcode
    expose :quantity
    expose :reserved_quantity
    expose :buy_quota
    expose :buy_quota_days
    expose :quantity_updated_at
    expose :position
  end
end
