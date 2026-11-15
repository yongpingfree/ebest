# frozen_string_literal: true
module BeansAdmin::API::Entities
  class WebCustomList < SimpleWebCustomList
    expose :item_ids, documentation: { type: Array[Integer], desc: "商品列表", documentation: { param_type: "body" } }
    expose :items, using: ::BeansAdmin::API::Entities::MinimalItem
  end
end
