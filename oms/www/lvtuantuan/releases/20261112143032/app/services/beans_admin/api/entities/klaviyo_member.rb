# frozen_string_literal: true

module BeansAdmin::API::Entities
  class KlaviyoMember < ::CommonEntities::Model
    expose :mobile
    expose :sign_up_channel
    expose :email
    expose :receive_activity_email
    expose :first_name
    expose :last_name
    expose :email_confirmation_url
  end
end
