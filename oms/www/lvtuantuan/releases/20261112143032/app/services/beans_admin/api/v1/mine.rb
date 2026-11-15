# frozen_string_literal: true

module BeansAdmin
  class API::V1::Mine < ::API
    namespace :mine, desc: "我的 API" do
      desc "详情", {
        success: API::Entities::AdminUser
      }
      get do
        present current_admin_user, with: API::Entities::AdminUser
      end
    end
  end
end
