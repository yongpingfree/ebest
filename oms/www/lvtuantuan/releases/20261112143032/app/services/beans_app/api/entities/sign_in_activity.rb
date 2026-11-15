# frozen_string_literal: true

module BeansApp::API::Entities
  class SignInActivity < ::CommonEntities::Model
    translate_expose :title
    expose :banner
    expose :detail_image
    expose :start_at
    expose :end_at
    expose :reward_integral_each_time
    expose :extra_reward_type, documentation: { desc: "consecutive: 连续签到, accumulative: 累计签到" }
    expose :sign_in_times
    expose :extra_reward_integral
  end
end
