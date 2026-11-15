# frozen_string_literal: true

module BeansAdmin
  class API::V1::EventFormRecords < ::API
    # 自定义页面 API

    namespace :event_form_records, desc: "活动纪录 API" do
      helpers do
        def includes
          [user: :member]
        end
      end
      desc "获取活动纪录", {
        success: API::Entities::EventFormRecord,
        is_array: true,
        action_type: "searched",
        page_type: "event_form_records",
        skip_authentication: true
      }
      paginate
      get do
        authorize_and_response_collection
      end
    end
  end
end
