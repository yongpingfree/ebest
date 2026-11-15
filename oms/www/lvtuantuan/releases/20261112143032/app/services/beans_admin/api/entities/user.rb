# frozen_string_literal: true

module BeansAdmin::API::Entities
  class User < SimpleUser
    expose :member_id
    expose :member_mobile
  end
end
