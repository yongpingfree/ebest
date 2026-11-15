# frozen_string_literal: true

module BeansApp
  class API::V1::AppTextMessages < ::API
    namespace :app_text_messages do
      helpers do
        def default_order
          @default_order ||= "created_at DESC"
        end

        def end_of_association_chain
          resource_class.where(kind: params[:kind])
        end

        def resource
          @resource ||= current_user.app_text_messages.find(params[:id])
        end
      end

      desc "消息列表", {
        success: API::Entities::AppTextMessage,
        is_array: true
      }
      params do
        requires :kind, type: String, values: -> { ::MagicBean::AppTextMessage.kinds.keys }, desc: "消息类型，`order_tracking`: 订单追踪，`customer_service`: 客服通知，`sku_in_stock`: 到货通知"
      end
      paginate
      get do
        authorize_and_response_collection
      end

      desc "批量阅读消息", {
        success: API::Entities::PushMessage
      }
      params do
        requires :kind, type: String, values: -> { ["all"] + ::MagicBean::AppTextMessage.kinds.keys }, desc: "消息类型，`all`: 全部, `order_tracking`: 订单追踪，`customer_service`: 客服通知，`sku_in_stock`: 到货通知"
      end
      get "batch_read" do
        authorize! :read, resource_class

        current_user.batch_read_app_text_messages(params[:kind])

        response_success
      end

      desc "批量删除消息", {
        success: API::Entities::PushMessage
      }
      params do
        requires :kind, type: String, values: -> { ::MagicBean::AppTextMessage.kinds.keys }, desc: "消息类型，`all`: 全部, `order_tracking`: 订单追踪，`customer_service`: 客服通知，`sku_in_stock`: 到货通知"
      end
      delete "batch_delete" do
        authorize! :destroy, resource_class

        current_user.app_text_messages.send(params[:kind]).destroy_all

        response_success
      end

      route_param :id do
        desc "请求消息详情，并标记该消息为已读状态", {
          success: API::Entities::AppTextMessage
        }
        get do
          authorize_and_run_member_action(:read)
        end

        desc "删除消息", {
          detail: <<-NOTES.strip_heredoc
            ```json
            {
              code: 200,
              message: "ok"
            }
            ```
          NOTES
        }
        delete do
          standard_destroy(resource)
        end
      end
    end
  end
end
