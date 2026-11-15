# frozen_string_literal: true

module BeansAdmin::API::Entities
  class Member < ::CommonEntities::Model
    expose :mobile, documentation: { type: String, desc: "手机号码" }
    expose :birthday, documentation: { type: String, desc: "生日" }
    expose :available_integral, documentation: { type: String, desc: "可用积分" }
    expose :blocked_integral, documentation: { type: String, desc: "冻结积分" }
    expose :cumulative_integral, documentation: { type: String, desc: "累积获取积分" }
    expose :user, using: BeansAdmin::API::Entities::User
    expose :inviter_id
    expose :inviter_nickname
    expose :app_available_integral
    expose :app_blocked_integral
    expose :app_cumulative_integral
    expose :channel
    expose :can_edit_birthday
    expose :email
    expose :email_verified_at
    expose :receive_activity_email
    expose :first_name
    expose :last_name
  end
end
