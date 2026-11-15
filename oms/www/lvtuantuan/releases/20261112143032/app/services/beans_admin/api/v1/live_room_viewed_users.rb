# frozen_string_literal: true

module BeansAdmin
  class API::V1::LiveRoomViewedUsers < ::API
    namespace :live_room_viewed_users, desc: "直播观看用户 API" do
      helpers do
        def includes
          [:user]
        end
      end
      desc "直播观看用户列表", {
        success: API::Entities::LiveRoomViewedUser,
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
