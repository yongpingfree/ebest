# frozen_string_literal: true

module BeansAdmin::API::Entities
  class MinimalStockKeepingUnit < ::CommonEntities::Model
    expose :no, documentation: { type: String, desc: "货号" }
    expose :item_id
    expose :title
    expose :barcode, documentation: { type: String, desc: "条形码" }
    expose :on_sale, documentation: { type: Grape::API::Boolean, desc: "是否上架" }
    expose :store_id
    expose :display_title

    def display_title
      "#{object.no} - #{object.title}"
    end
  end
end
