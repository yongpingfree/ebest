# frozen_string_literal: true

module BeansAdmin::API::Entities
  class BannerClick < ::CommonEntities::Model
    expose :date
    expose :count
    expose :url
  end
end
