# frozen_string_literal: true
module BeansApp::API::Entities
  class CustomList < ::CommonEntities::Model
    expose :title
    expose :kind
    expose :as_category
    expose :parent_category_id
    expose :icon
    expose :bg_color
    expose :position
    expose :show_discount_rate
    expose :items_count
    expose :ae_drop_shipper
    expose :show_items, as: :items, using: ::BeansApp::API::Entities::CustomListItem, if: lambda { |_, options| options[:with_items] }

    def items_count
      if options[:with_items]
        show_items.size
      else
        0
      end
    end

    def show_items
      if options[:limit]
        specified_count = options[:id_count_map].try(:[], object.id.to_s).to_i
        count = specified_count.positive? ? specified_count : (options[:items_limit] || 5)

        items_with_condition.first(count)
      else
        items_with_condition
      end
    end

    def items_with_condition
      return @items if @items.present?
      @items =
        if options[:delivery_area]
          object.on_sale_custom_list_items
        else
          object.not_merchant_delivery_custom_list_items
        end

      @items = @items.select do |custom_list_item|
        filter_same_day = options[:same_day_delivery] ? custom_list_item.item.same_day_delivery? : true
        custom_list_item.item.channel_match?(ebest_channel) && filter_same_day
      end
    end
  end
end
