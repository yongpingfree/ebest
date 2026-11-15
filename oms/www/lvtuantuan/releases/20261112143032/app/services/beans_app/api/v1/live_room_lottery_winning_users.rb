# frozen_string_literal: true

module BeansApp
  class API::V1::LiveRoomLotteryWinningUsers < ::API
    namespace :live_room_lottery_winning_users, desc: "我的直播间中奖记录 API" do
      helpers do
        def permitted_params
          [:address_id]
        end

        def end_of_association_chain
          current_user.live_room_lottery_winning_users
        end
      end

      desc "我的中奖记录列表", {
        success: API::Entities::LiveRoomLotteryWinningUser,
        is_array: true
      }
      paginate
      get do
        authorize_and_response_collection
      end

      route_param :id do
        desc "直播间中奖详情", {
          success: API::Entities::LiveRoomLotteryWinningUser
        }
        get do
          authorize_and_response_resource
        end

        desc "填写中奖信息", {
          success: API::Entities::LiveRoomLotteryWinningUser
        }
        params do
          requires :address_id, type: Integer, desc: "收货地址ID"
        end
        put do
          authorize_and_update_resource
        end
      end
    end
  end
end
