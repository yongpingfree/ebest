# frozen_string_literal: true

module BeansAdmin
  class API::V1::LiveRoomOrders < ::API
    namespace :live_room_orders, desc: "直播订单 API" do
      helpers do
        def includes
          [:user, :order]
        end
      end
      desc "直播订单列表", {
        success: API::Entities::LiveRoomOrder,
        is_array: true
      }
      paginate
      params do
        requires :live_room_id_eq, type: Integer, desc: "直播间 ID"
      end
      get do
        authorize_and_response_collection
      end
    end
  end
end
