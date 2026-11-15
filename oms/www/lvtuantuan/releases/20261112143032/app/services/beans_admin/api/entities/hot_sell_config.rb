# frozen_string_literal: true

module BeansAdmin::API::Entities
  class HotSellConfig < ::CommonEntities::Model
    expose :last_x_days
    expose :show_item_nums
    expose :contains_order_gift
    expose :contains_order_pool_gift
    expose :is_show_storage_on_sale
    expose :enabled
    expose :category_id
    expose :category_name
    expose :store_name
    expose :position
  end
end
