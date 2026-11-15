# frozen_string_literal: true

module BeansAdmin
  class API::V1::EventPages < ::API
    # 自定义页面 API

    namespace :event_pages, desc: "活动页面 API" do
      helpers do
        def includes
          [:event_form_records]
        end
      end
      desc "获取活动页面", {
        success: API::Entities::EventPage,
        is_array: true,
        action_type: "searched",
        page_type: "event_page",
        skip_authentication: true
      }
      paginate
      get do
        response_collection
      end
    end
  end
end
