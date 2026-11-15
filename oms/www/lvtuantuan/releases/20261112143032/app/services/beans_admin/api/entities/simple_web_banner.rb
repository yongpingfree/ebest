# frozen_string_literal: true

module BeansAdmin::API::Entities
  class SimpleWebBanner < ::CommonEntities::Model
    expose :remark
    expose :displayed
    expose :store_name
    expose :page_location
  end
end
