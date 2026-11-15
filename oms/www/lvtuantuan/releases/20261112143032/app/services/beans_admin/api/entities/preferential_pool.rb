# frozen_string_literal: true

module BeansAdmin::API::Entities
  class PreferentialPool < SimplePreferentialPool
    expose :skus, using: BeansAdmin::API::Entities::SimpleStockKeepingUnit
    expose :preferences_coupon_templates
    expose :preferences_skus

    def preferences_skus
      object.human_preferences_skus
    end
  end
end
