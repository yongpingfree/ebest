# frozen_string_literal: true

module BeansAdmin::API::Entities
  class SimplePreferentialPool < ::CommonEntities::Model
    translate_expose :title, documentation: { type: String, desc: "标题" }
    expose :kind
    expose :sku_ids
    expose :threshold_kind
    expose :at_least_amount_in_cent
    expose :at_least_amount_in_yuan
    expose :at_least_quantity
    expose :start_at
    expose :end_at
    expose :preferences
    expose :enabled
  end
end
