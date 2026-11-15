# frozen_string_literal: true

module BeansAdmin::API::Entities
  class ReportPage < SimpleReportPage
    expose :admin_user_ids
    expose :admin_users, using: BeansAdmin::API::Entities::MinimalAdminUser
  end
end
