# frozen_string_literal: true

module BeansApp::API::Entities
  class TimeLimitedPromotionSku < ::CommonEntities::Model
    expose :item_id
    expose :human_title, as: :title
    expose :item_show_on_sale_soon_tag, as: :show_on_sale_soon_tag
    expose :image
    expose :is_on_sale?, as: :on_sale
    expose :ae_drop_shipper, as: :ae_drop_shipper
    expose :price_in_yuan
    expose :strikethrough_price_in_yuan
    expose :cover
    expose :is_virtual
  end
end
