# frozen_string_literal: true

module BeansApp::API::Entities
  class SkuGroupon < ::CommonEntities::Model
    expose :enabled
    expose :price_in_yuan
  end
end
