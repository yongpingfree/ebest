# frozen_string_literal: true

module BeansAdmin
  class API::V1::LiveRoomViewedUserStats < ::API
    namespace :live_room_viewed_user_stats, desc: "直播观看用户实时数据API" do
      desc "直播观看用户实时数据"
      params do
        requires :live_room_id, type: Integer, desc: "直播间 ID"
      end
      get :real_time_viewed_chart do
        authorize! :read, resource_class

        present resource_class.real_time_chart_data(params[:live_room_id])
      end
    end
  end
end
