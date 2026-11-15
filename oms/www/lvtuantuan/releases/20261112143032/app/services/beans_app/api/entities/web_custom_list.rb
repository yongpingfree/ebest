# frozen_string_literal: true
module BeansApp::API::Entities
  class WebCustomList < ::CommonEntities::Model
    expose :title
    expose :position
    expose :orientation, documentation: { type: String, desc: "展示方向" }
    expose :show_items, as: :items, using: ::BeansApp::API::Entities::SimpleItem, if: lambda { |_, options| options[:with_items] }

    def show_items
      object.items.on_sale_with_stock.not_gift.first(options[:items_limit])
    end
  end
end
