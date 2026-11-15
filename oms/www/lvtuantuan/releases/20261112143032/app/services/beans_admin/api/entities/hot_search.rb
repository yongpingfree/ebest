# frozen_string_literal: true

module BeansAdmin::API::Entities
  class HotSearch < ::CommonEntities::Model
    translate_expose :word
    expose :position
    expose :show
    expose :store_name
    expose :channels
    expose :ae_drop_shipper
  end
end
