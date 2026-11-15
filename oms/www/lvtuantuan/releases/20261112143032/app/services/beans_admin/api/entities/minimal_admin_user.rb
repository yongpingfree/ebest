# frozen_string_literal: true

module BeansAdmin::API::Entities
  class MinimalAdminUser < ::CommonEntities::Model
    expose :name, documentation: { type: String, desc: "管理员名称" }
    expose :mobile, documentation: { type: String, desc: "手机号码" }
    expose :email, documentation: { type: String, desc: "邮箱" }
  end
end
