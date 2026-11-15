# frozen_string_literal: true
module BeansAdmin::API::Entities
  class UserRecommendedProduct < ::CommonEntities::Model
    expose :recommended_products
    expose :mobile
    expose :wechat
    expose :user, using: ::BeansAdmin::API::Entities::User
    expose :images
  end
end
