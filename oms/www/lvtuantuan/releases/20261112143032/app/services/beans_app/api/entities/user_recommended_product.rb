# frozen_string_literal: true
module BeansApp::API::Entities
  class UserRecommendedProduct < ::CommonEntities::Model
    expose :recommended_products
    expose :mobile
    expose :wechat
    expose :images
  end
end
