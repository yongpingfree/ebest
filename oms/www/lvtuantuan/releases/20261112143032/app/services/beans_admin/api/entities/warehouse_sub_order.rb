# frozen_string_literal: true

module BeansAdmin::API::Entities
  class WarehouseSubOrder < ::CommonEntities::Model
    expose :no
    expose :type
    expose :status
    expose :quantity
    expose :paid_at
    expose :remark
    expose :sync_status
    expose :express_carrier
  end
end
