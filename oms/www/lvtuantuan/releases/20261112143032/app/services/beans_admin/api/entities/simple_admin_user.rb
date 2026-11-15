# frozen_string_literal: true

module BeansAdmin::API::Entities
  class SimpleAdminUser < MinimalAdminUser
    expose :state
    expose :stores, using: BeansAdmin::API::Entities::SimpleStore
    expose :store_ids
    expose :role, documentation: { type: String, desc: "管理员角色", values: -> () { MagicBean::AdminUser.roles.keys } }
    expose :receive_notify_email, documentation: { type: Grape::API::Boolean, desc: "是否接收待处理订单通知邮件" }
    expose :can_read_category_ids
    expose :role_template_id
    expose :role_template_name

    def role_template_name
      object.role_template&.name
    end
  end
end
