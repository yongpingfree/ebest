# frozen_string_literal: true

module BeansApp
  class API::V1::HotSearches < ::API
    # 热搜 API

    namespace :hot_searches, desc: "热搜 API" do
      helpers do
        def default_order
          "position asc"
        end

        def end_of_association_chain
          resource_class.where(store_id: [current_store_id, nil]).show.of_channel(ebest_channel)
        end
      end

      desc "获取热搜", {
        success: API::Entities::HotSearch,
        is_array: true,
        skip_authentication: true
      }
      paginate
      params do
        optional :ae_drop_shipper_eq, type: Boolean, default: false
      end
      get do
        response_collection
      end
    end
  end
end
