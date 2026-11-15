# frozen_string_literal: true
module BeansAdmin
  class API::V1::LiveRooms < ::API
    namespace :live_rooms, desc: "直播间管理 API" do
      helpers BeansAdmin::Helpers::FileUploadHelper
      helpers do
        def permitted_params
          [
            :title, :host_id, :host_nickname, :start_at, :app_push_protocol, :app_pull_protocol, :admin_user_id,
            :viewed_count_offset, :viewed_count_multiplier, :liked_count_offset, :liked_count_multiplier, :coupon_package_id,
            :bg_img, :bg_color, :announcement, :highlighted_sku_id, :subscription_noti_title, :subscription_noti_body,
            :custom_page_id, :custom_page_icon, :share_icon, :subscription_count_offset, :subscription_count_multiplier,
            :lottery_win_limits, :orientation, live_room_skus_attributes: [:id, :stock_keeping_unit_id, :_destroy]
          ]
        end

        def includes
          [:host]
        end

        def build_resource
          @resource = end_of_association_chain.new(resource_params.merge({
            store_id: current_store_id,
            admin_user_id: current_user.id
          }))
        end
      end

      desc "直播间列表", {
        success: API::Entities::SimpleLiveRoom,
        is_array: true
      }
      paginate
      params do
        optional :title_cont, type: String, desc: "标题包含"
        optional :start_at_gteq_datetime, type: DateTime, desc: "开始时间大于等于"
      end
      get do
        authorize_and_response_collection
      end

      desc "创建直播间", {
        success: API::Entities::LiveRoom
      }
      params do
        requires :all, using: API::Entities::LiveRoom.documentation.dup.extract!(
          :title, :start_at, :host_id, :host_nickname, :app_push_protocol, :app_pull_protocol, :orientation,
          :bg_img, :bg_color, :subscription_noti_title, :subscription_noti_body, :lottery_win_limits
        )
        optional :all, using: API::Entities::LiveRoom.documentation.dup.extract!(
          :announcement, :custom_page_id, :custom_page_icon
        )
        requires :live_room_skus_attributes, type: Array do
          requires :all, using: API::Entities::LiveRoomSku.documentation.slice(:stock_keeping_unit_id)
        end
        all_or_none_of :custom_page_id, :custom_page_icon
      end
      post do
        authorize_and_create_resource
      end

      route_param :id do
        desc "直播间详情", {
          success: API::Entities::LiveRoom
        }
        get do
          authorize_and_response_resource
        end

        desc "更新直播间", {
          success: API::Entities::LiveRoom
        }
        params do
          optional :all, using: API::Entities::LiveRoom.documentation.dup.extract!(
            :title, :start_at, :host_id, :host_nickname, :app_push_protocol, :app_pull_protocol, :coupon_package_id,
            :bg_img, :bg_color, :announcement, :subscription_noti_title, :subscription_noti_body,
            :custom_page_id, :custom_page_icon, :lottery_win_limits, :orientation
          )
          optional :live_room_skus_attributes, type: Array do
            optional :all, using: API::Entities::LiveRoomSku.documentation.slice(:stock_keeping_unit_id)
            optional :id, type: Integer
            optional :_destroy, type: Grape::API::Boolean
          end
          all_or_none_of :custom_page_id, :custom_page_icon
        end
        put do
          if resource.finished_state?
            response_error("不能更新已结束的直播")
          end

          authorize_and_update_resource
          resource.broadcast_live_room_update
        end

        desc "开始直播", {
          success: API::Entities::LiveRoom
        }
        post :start do
          if resource.may_start?
            authorize_and_run_member_action(:start!)
          else
            response_error("不能开始这场直播")
          end
        end

        desc "结束直播", {
          success: API::Entities::LiveRoom
        }
        post :finish do
          if resource.may_finish?
            authorize_and_run_member_action(:finish!)
          else
            response_error("不能结束这场直播")
          end
        end

        desc "更新直播中的公告", {
          success: API::Entities::LiveRoom
        }
        params do
          requires :announcement, type: String
        end
        put :announcement do
          if resource.live_state?
            authorize_and_update_resource
            resource.broadcast_announcement_update
          else
            response_error("不能更新这场直播的公告")
          end
        end

        desc "置顶直播间 SKU", {
          success: API::Entities::SuccessfulResult
        }
        params do
          requires :sku_id, type: Integer
        end
        put :highlighted_sku do
          authorize! :update, resource_class

          if resource.update(highlighted_sku_id: params[:sku_id])
            resource.broadcast_highlighted_sku
            response_success("置顶成功")
          else
            response_error("置顶失败")
          end
        end

        desc "取消置顶直播间 SKU", {
          success: API::Entities::SuccessfulResult
        }
        put :reset_highlighted_sku do
          authorize! :update, resource_class

          if resource.update(highlighted_sku_id: nil)
            resource.broadcast_reset_highlighted_sku
            response_success("取消置顶成功")
          else
            response_error("取消置顶失败")
          end
        end

        desc "批量导入 SKU", {
          success: API::Entities::SuccessfulResult
        }
        params do
          requires :file_message, type: JSON, desc: "xlsx 文件信息"
        end
        post :batch_import_skus do
          authorize! :update, resource_class
          response_error("请选择 xlsx 文件") unless check_file_type(params[:file_message], "xlsx")

          success, message = resource.import_skus_via_excel params[:file_message]["tempfile"].path

          if success
            response_success message
          else
            response_error message
          end
        end

        desc "删除直播间", {
          success: API::Entities::SuccessfulResult
        }
        delete do
          authorize_and_destroy_resource
        end

        desc "导出直播订单列表"
        get "order_export" do
          authorize! :read, resource_class

          filename = "#{resource.title}-#{resource.start_at.strftime('%Y-%m-%d')}.xlsx"

          package = Axlsx::Package.new do |pkg|
            # 5个字段一行，方便查找对应的字段
            headers = %w[
              用户ID 订单编号 订单状态 delivery_date channel
              type actual_payment actual_payment_incl_service_fee original_order_amount freight
              coin gift_card coupon parent_category child_category
              sku gmv_sku_level gp_sku_level title quantity
              original_unit_price real_price_in_price total_paid gst_rate gst
              marketing_mode shoppingunit
            ]
            types = %i[
              integer string string string string
              string float float float float
              integer float string string string
              string string string string integer
              float float float string float
              string string
            ]

            pkg.workbook.add_worksheet do |sheet|
              sheet.add_row headers

              resource.orders.includes(:coupon).order(created_at: :asc).find_each do |o|
                order_info = [
                  o.user_id, o.no, I18n.t("activerecord.attributes.magic_bean/order.status/#{o.status}"), o.delivery_date, o.channel,
                  o.payment_type_name, o.payment_in_yuan, o.final_amount_in_yuan, o.amount_in_yuan, o.freight_in_yuan,
                  o.cost_integral, o.gift_card_amount_in_yuan, o.coupon&.title
                ]

                o.order_items.includes([stock_keeping_unit: [:item], item: [:translations, parent_category: [:translations], category: [:translations]]]).each_with_index do |oi, index|
                  sku = oi.stock_keeping_unit
                  sku_info = [
                    oi.item_parent_category_name, oi.item_category_name,
                    sku.no, sku.gmv_sku_level, sku.gp_sku_level, oi.sku_human_title, oi.quantity,
                    oi.price_in_yuan, oi.real_price_in_yuan, oi.real_amount_in_yuan, "#{oi.gst_percent}%", oi.gst_amount_in_yuan,
                    I18n.t("activerecord.attributes.magic_bean/stock_keeping_unit/marketing_modes.#{oi.marketing_mode}"), sku.shoppingunit
                  ]
                  # 每一行都展示全部信息，方便excel排序
                  sheet.add_row order_info + sku_info, types: types
                end
              end
            end
          end

          content_type "application/octet-stream"
          header["Content-Disposition"] = "attachment; filename=#{filename}"
          env["api.format"] = :binary

          package.to_stream.read
        end
      end
    end
  end
end
