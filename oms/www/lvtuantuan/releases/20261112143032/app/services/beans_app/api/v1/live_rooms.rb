# frozen_string_literal: true

module BeansApp
  class API::V1::LiveRooms < ::API
    namespace :live_rooms, desc: "直播间 API" do
      route_param :id do
        desc "直播间详情", {
          detail: "主播获取详情时会增加返回推流地址 `app_live_push_url`",
          success: API::Entities::LiveRoom,
          skip_authentication: true
        }
        get do
          authorize_and_response_resource
        end

        desc "直播间产品列表", {
          success: API::Entities::LiveRoomSku,
          skip_authentication: true,
          is_array: true
        }
        get "skus" do
          authorize! :read, resource
          skus = resource.live_room_skus.includes([stock_keeping_unit: :item])
          present skus, with: ::BeansApp::API::Entities::LiveRoomSku
        end

        desc "直播间最新50条评论", {
          skip_authentication: true,
          is_array: true
        }
        get "comments" do
          authorize! :read, resource
          current_comment_count = resource.redis_latest_comments.size
          if current_comment_count > MagicBean::LiveRoom::LATEST_COMMENT_COUNT
            resource.redis_latest_comments.shift(current_comment_count - MagicBean::LiveRoom::LATEST_COMMENT_COUNT)
          end

          comments = resource.redis_latest_comments.to_a
          present comments
        end

        desc "开始直播", {
          detail: "只有主播能开始直播",
          success: API::Entities::LiveRoom
        }
        post :start do
          if resource.live_state?
            return response_success
          end

          if resource.may_start? && current_user.id == resource.host_id
            authorize_and_run_member_action(:start!)
          else
            response_error(I18n.t("grape.live_rooms.cannot_start_live"), :forbidden)
          end
        end

        desc "结束直播", {
          detail: "只有主播能结束直播",
          success: API::Entities::LiveRoom
        }
        post :finish do
          if resource.finished_state?
            return response_success
          end

          if resource.may_finish? && current_user.id == resource.host_id
            authorize_and_run_member_action(:finish!)
          else
            response_error(I18n.t("grape.live_rooms.cannot_finish_live"), :forbidden)
          end
        end

        desc "直播间点击抽奖箱参与抽奖", {
          success: API::Entities::SuccessfulResult
        }
        post :draw_box_click do
          if resource.has_active_lottery? && resource.current_lottery_click_to_draw?
            resource.add_user_to_current_lottery(current_user.id)
            response_success
          else
            response_error I18n.t("grape.live_rooms.failed_to_draw")
          end
        end

        namespace :subscriptions, desc: "订阅直播 API" do
          desc "订阅该次直播开播通知", {
            detail: "只有未开播状态才能订阅成功，多次订阅均返回成功。其他直播间状态返回 400 错误。",
            success: API::Entities::SuccessfulResult
          }
          post do
            if resource.pending_state?
              subscription = current_user.live_room_subscriptions.find_or_create_by(live_room_id: params[:id])
              if subscription.valid?
                response_success
              else
                response_error I18n.t("grape.live_rooms.subscribe_failed")
              end
            elsif resource.live_state?
              response_error(I18n.t("grape.live_rooms.subscribe_failed_when_live"))
            elsif resource.finished_state?
              response_error(I18n.t("grape.live_rooms.subscribe_failed_when_finished"))
            else
              response_error(I18n.t("grape.live_rooms.subscribe_failed"))
            end
          end
        end
      end
    end
  end
end
