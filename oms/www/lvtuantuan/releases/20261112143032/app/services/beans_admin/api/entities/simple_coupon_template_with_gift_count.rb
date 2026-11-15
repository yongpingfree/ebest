# frozen_string_literal: true

module BeansAdmin::API::Entities
  class SimpleCouponTemplateWithGiftCount < ::CommonEntities::Model
    expose :title, documentation: { desc: "名字" }
    expose :need_at_least_amount, documentation: { type: Grape::API::Boolean, desc: "是否无门槛使用"}
    expose :at_least_amount_in_yuan, documentation: { type: Integer, desc: "订单满减金额（单位：元）"}
    expose :gift_count

    def gift_count
      options[:gifts_count]["#{object.id}"] if options[:gifts_count].present?
    end
  end
end
