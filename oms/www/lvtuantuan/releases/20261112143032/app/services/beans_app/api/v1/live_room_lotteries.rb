# frozen_string_literal: true

module BeansApp
  class API::V1::LiveRoomLotteries < ::API
    namespace :live_room_lotteries, desc: "直播间抽奖 API" do
      route_param :id do
        desc "直播间抽奖详情", {
          success: API::Entities::LiveRoomLottery,
          skip_authentication: true
        }
        get do
          present resource, with: API::Entities::LiveRoomLottery
        end

        namespace :winning_users, desc: "中奖用户 API" do
          desc "中奖用户列表", {
            success: API::Entities::PublicLotteryWinningUser,
            skip_authentication: true
          }
          get do
            present resource.live_room_lottery_winning_users, with: API::Entities::PublicLotteryWinningUser
          end

          route_param :winning_user_id do
            helpers do
              def current_winning_user
                @current_winning_user ||= current_user.live_room_lottery_winning_users.find(params[:winning_user_id])
              end
            end
            desc "填写中奖信息", {
              success: API::Entities::LiveRoomLotteryWinningUser
            }
            params do
              requires :address_id, type: Integer, desc: "收货地址ID"
            end
            put do
              if current_winning_user.update(address_id: params[:address_id])
                present current_winning_user, with: API::Entities::LiveRoomLotteryWinningUser
              else
                response_record_error current_winning_user
              end
            end
          end
        end
      end
    end
  end
end
