# frozen_string_literal: true

module BeansApp
  class API::V1::PushMessages < ::API
    namespace :push_messages do
      helpers do
        def default_order
          @default_order ||= "push_at DESC"
        end

        # 如果设置了置顶用户，需要过滤
        def end_of_association_chain
          (resource_class.where("user_ids @> ARRAY[?]::integer[]", [current_user.id])
            .or(resource_class.where(user_ids: [])))
            .where(store_id: [nil, current_store_id], push_at: 1.month.ago.beginning_of_day..Time.current, kind: ((params[:kind].blank? || params[:kind] == "all") ? ::MagicBean::PushMessage.kinds.keys : params[:kind]))
        end

        def includes
          [:push_message_read_logs]
        end
      end

      desc "消息列表", {
        success: API::Entities::PushMessage,
        is_array: true
      }
      params do
        optional :kind, type: String, values: -> { ::MagicBean::PushMessage.kinds.keys }, desc: "消息类型，`service_notification`: 服务通知，`promotion`: 优惠促销"
      end
      paginate
      get do
        authorize_and_response_collection
      end

      desc "批量阅读消息", {
        success: API::Entities::PushMessage
      }
      params do
        requires :kind, type: String, values: -> { ["all"] + ::MagicBean::PushMessage.kinds.keys }, desc: "消息类型，`all`: 全部，`service_notification`: 服务通知，`promotion`: 优惠促销"
      end
      get "batch_read" do
        authorize! :read, resource_class

        read_message_ids = current_user.push_message_read_logs.pluck(:push_message_id)
        end_of_association_chain.each do |message|
          next if read_message_ids.include?(message.id)
          message.read(user: current_user, inc_views: false)
        end

        response_success
      end

      desc "消息列表各类型消息最新消息"
      get "newest" do
        authorize! :read, resource_class

        push_messages = (resource_class.where("user_ids @> ARRAY[?]::integer[]", [current_user.id]).or(resource_class.where(user_ids: []))).accessible_by(current_ability).where(store_id: [nil, current_store_id], push_at: 1.month.ago.beginning_of_day..Time.current).order(default_order)
        app_text_messages = current_user.app_text_messages.order("created_at DESC")

        target_message = {}
        
        MagicBean::PushMessage.kinds.keys.each do |key|
          message = push_messages.send(key).first
          target_message[key] = message ? { title: message.title, content: message.content, created_at: message.push_at } : {}
        end

        MagicBean::AppTextMessage.kinds.keys.each do |key|
          message = app_text_messages.send(key).first
          target_message[key] = message ? { title: message.title, content: message.content, created_at: message.created_at } : {}
        end

        target_message
      end

      route_param :id do
        desc "消息详情", {
          success: API::Entities::PushMessage
        }
        get do
          authorize! :read, resource
          # 先判断是否未读，未读是从消息中心点进来的，这时候需要标记为已读
          log = resource.push_message_read_logs.find_by(user_id: current_user.id)
          resource.read(user: current_user) unless log
          response_resource
        end

        desc "阅读消息详情", {
          success: API::Entities::PushMessage
        }
        get :read do
          authorize_and_run_member_action(:read, {}, user: current_user)
        end
      end
    end
  end
end
