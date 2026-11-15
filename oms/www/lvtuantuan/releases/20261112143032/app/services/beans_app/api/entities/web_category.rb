# frozen_string_literal: true

module BeansApp::API::Entities
  class WebCategory < ::CommonEntities::Model
    expose :name, :icon, :bg_color, :display_length, :filter_icon
    expose :need_age_verification
    expose :children_on_show, as: :children, using: ::BeansApp::API::Entities::WebCategory, if: lambda { |object, options| object.parent_id.blank? && options[:with_children] }
    expose :items_count, if: lambda { |object, options| object.parent_id? && options[:with_items] }
    expose :preview_items, as: :items, using: ::BeansApp::API::Entities::SimpleItem, if: lambda { |object, options| object.parent_id? && options[:with_items] }

    def all_items
      # TODO: 这里无法查到次分类商品
      return @all_items if @all_items.present?
      @all_items =
        if options[:delivery_area]
          object.on_sale_items
        else
          object.not_merchant_delivery_items
        end

      @all_items = @all_items.select do |item|
        filter_same_day = options[:same_day_delivery] ? item.same_day_delivery? : true
        item.store_id == current_store_id && item.channel_match?(ebest_channel) && filter_same_day
      end
    end

    def preview_items
      all_items.first(8)
    end

    def items_count
      all_items.size
    end

    # TODO: 优化: 这里会有 N+1
    def children_on_show
      object.children_on_show.select do |child|
        child.id.in? options[:has_items_category_ids]
      end
    end
  end
end
