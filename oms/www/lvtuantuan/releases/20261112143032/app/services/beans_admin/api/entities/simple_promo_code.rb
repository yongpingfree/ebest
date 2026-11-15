# frozen_string_literal: true

module BeansAdmin::API::Entities
  class SimplePromoCode < ::CommonEntities::Model
    expose :total_avaliable_count
    expose :used_count
    expose :code
    expose :promo_code_template_id
  end
end
