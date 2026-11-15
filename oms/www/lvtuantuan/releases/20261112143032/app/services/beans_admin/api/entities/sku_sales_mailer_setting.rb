# frozen_string_literal: true

module BeansAdmin::API::Entities
  class SkuSalesMailerSetting < SimpleSkuSalesMailerSetting
    expose :can_edit_send_at?, as: :can_edit_send_at
    expose :skus, using: BeansAdmin::API::Entities::MinimalStockKeepingUnit
  end
end
