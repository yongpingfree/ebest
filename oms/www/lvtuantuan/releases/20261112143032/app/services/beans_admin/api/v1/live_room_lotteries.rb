# frozen_string_literal: true

module BeansAdmin
  class API::V1::LiveRoomLotteries < ::API
    namespace :live_room_lotteries, desc: "直播间抽奖管理 API" do
      helpers do
        def permitted_params
          [
            :live_room_id, :name, :luck_limit, :duration_in_minutes, :winning_description,
            :remark, :award_cover, :draw_method
          ]
        end
      end

      desc "直播间抽奖列表", {
        success: API::Entities::LiveRoomLottery,
        is_array: true
      }
      paginate
      params do
        requires :live_room_id_eq, type: Integer, desc: "直播间 ID"
      end
      get do
        authorize_and_response_collection
      end

      desc "创建直播间抽奖", {
        success: API::Entities::LiveRoomLottery
      }
      params do
        requires :all, using: API::Entities::LiveRoomLottery.documentation.dup.extract!(
          :live_room_id, :name, :luck_limit, :duration_in_minutes, :award_cover
        )
        optional :all, using: API::Entities::LiveRoomLottery.documentation.dup.extract!(
          :remark
        )
      end
      post do
        authorize_and_create_resource
      end

      desc "导出直播间抽奖列表"
      params do
        requires :live_room_id_eq, type: Integer, desc: "直播间 ID"
      end
      get "export" do
        authorize! :read, resource_class

        live_room = MagicBean::LiveRoom.find(params[:live_room_id_eq])
        filename = "#{live_room.title}-中奖明细-#{Date.current.strftime('%Y-%m-%d')}.xlsx"

        package = Axlsx::Package.new do |pkg|
          headers = %w[编号 名称 昵称 手机号 收货地址]
          types = %i[integer string string string string]

          pkg.workbook.add_worksheet do |sheet|
            sheet.add_row headers

            live_room.live_room_lotteries.includes(:live_room_lottery_winning_users).each do |lottery|
              lottery.live_room_lottery_winning_users.each do |winning_user|
                row = [lottery.id, lottery.name, winning_user.user_nickname, winning_user.user_member_mobile, winning_user.human_receiver_properties]
                sheet.add_row(row, types: types)
              end
            end
          end
        end

        content_type "application/octet-stream"
        header["Content-Disposition"] = "attachment; filename=#{filename}"
        env["api.format"] = :binary

        package.to_stream.read
      end

      route_param :id do
        desc "直播间抽奖详情", {
          success: API::Entities::LiveRoomLottery
        }
        get do
          authorize_and_response_resource
        end

        desc "更新直播间抽奖", {
          success: API::Entities::LiveRoomLottery
        }
        params do
          optional :all, using: API::Entities::LiveRoom.documentation.dup.extract!(
            :live_room_id, :name, :luck_limit, :duration_in_minutes, :remark, :award_cover
          )
        end
        put do
          authorize_and_update_resource
        end

        desc "开始抽奖", {
          success: API::Entities::LiveRoomLottery
        }
        post :start do
          if resource.live_room.live_state? && resource.may_start?
            authorize_and_run_member_action(:start!)
          else
            response_error("不能开始该抽奖")
          end
        end

        desc "删除直播间抽奖", {
          success: API::Entities::SuccessfulResult
        }
        delete do
          authorize_and_destroy_resource
        end
      end
    end
  end
end
