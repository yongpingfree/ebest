# frozen_string_literal: true

module BeansApp::API::Entities
  class Member < ::CommonEntities::Model
    expose :mobile
    expose :birthday
    expose :available_integral
    expose :blocked_integral
    expose :cumulative_integral
    expose :invite_code
    expose :app_available_integral
    expose :app_blocked_integral
    expose :app_cumulative_integral
    expose :channel
    expose :email
    expose :email_verified_at
    expose :can_edit_birthday
    expose :receive_activity_email
    expose :first_name
    expose :last_name
  end
end
