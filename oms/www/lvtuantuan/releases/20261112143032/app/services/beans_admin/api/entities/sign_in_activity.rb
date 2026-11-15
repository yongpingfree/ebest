# frozen_string_literal: true

module BeansAdmin::API::Entities
  class SignInActivity < ::CommonEntities::Model
    translate_expose :title, documentation: { type: String, desc: "标题" }
    expose :banner
    expose :detail_image
    expose :start_at
    expose :end_at
    expose :enabled
    expose :reward_integral_each_time
    expose :extra_reward_type
    expose :sign_in_times
    expose :extra_reward_integral
  end
end
