# frozen_string_literal: true

module BeansApp::API::Entities
  class SimpleItemWithMainImages < SimpleItem
    expose :main_images
    expose :top_left_item_tag_icon, documentation: { desc: "左上角标签图标" }
    expose :maximun_strikethrough_price_in_yuan, documentation: { desc: "最大划线价" }

    def top_left_item_tag_icon
      if options[:active_top_left_item_hash]
        options[:active_top_left_item_hash].find { |_, item_ids| item_ids.include?(object.id) }&.first
      else
        object.active_top_left_item_tag_icon
      end
    end
  end
end
