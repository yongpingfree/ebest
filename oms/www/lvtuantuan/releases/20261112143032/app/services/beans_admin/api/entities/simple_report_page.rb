# frozen_string_literal: true

module BeansAdmin::API::Entities
  class SimpleReportPage < ::CommonEntities::Model
    expose :name
    expose :content
    expose :creator_id
    expose :creator, with: BeansAdmin::API::Entities::MinimalAdminUser
    expose :link_path
  end
end
