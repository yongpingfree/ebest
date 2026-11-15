# frozen_string_literal: true

module BeansAdmin
  class API::V1::PushMessages < ::API

    namespace :push_messages, desc: "消息中心接口" do
      helpers BeansAdmin::Helpers::FileUploadHelper
      helpers do
        def includes
          [:admin_user, :store]
        end

        def permitted_params
          [:title, :content, :image, :push_at, :state, :kind, :path_customized, :path_customized_type, :path_customized_id, user_locales: [], user_ids: []]
        end

        def build_resource
          @resource = end_of_association_chain.new(resource_params.merge(admin_user_id: current_admin_user.id, store_id: current_store_id))
        end

        def set_path_customized_id
          if params[:path_customized]
            case params[:path_customized_type]
            when "MagicBean::Item"
              params[:path_customized_id] = params[:item_id]
            when "MagicBean::CustomPage"
              params[:path_customized_id] = params[:custom_page_id]
            when "MagicBean::CustomList"
              params[:path_customized_id] = params[:custom_list_id]
            else
              error!("自定义跳转页面类型错误", 400)
            end
          end
        end

      end

      desc "消息中心信息列表", {
        success: API::Entities::PushMessage,
        is_array: true,
      }
      paginate
      get do
        authorize_and_response_collection
      end

      desc "创建消息中心信息", {
        success: API::Entities::PushMessage
      }
      params do
        requires :all, using: API::Entities::PushMessage.documentation.dup.extract!(:title, :push_at, :state, :kind)
        optional :all, using: API::Entities::PushMessage.documentation.dup.extract!(:content, :image, :path_customized, :path_customized_type, :path_customized_id)
      end
      post do
        set_path_customized_id
        authorize_and_create_resource
      end

      route_param :id do
        desc "消息中心详情", {
          success: API::Entities::PushMessage
        }
        get do
          authorize_and_response_resource
        end

        desc "修改消息中心信息", {
          success: API::Entities::PushMessage
        }
        params do
          optional :all, using: API::Entities::PushMessage.documentation.dup.extract!(:title, :content, :image, :push_at, :state, :kind, :path_customized, :path_customized_id, :path_customized_type)
        end
        put do
          set_path_customized_id
          authorize_and_update_resource
        end

        desc "删除消息中心信息", {
          success: API::Entities::PushMessage
        }
        delete do
          authorize_and_destroy_resource
        end

        desc "导入用户", {
          detail: <<-NOTES.strip_heredoc
            ```json
            {
              code: 200,
              message: "ok"
            }
            ```
          NOTES
        }
        params do
          requires :users_file, type: File, desc: "支持xlsx文件"
        end
        post "import_users" do
          response_error("已发布消息不可导入指定用户") if resource.pushed?
          response_error("请选择 xlsx 文件") unless check_file_type(params[:users_file], "xlsx")

          error_messages = []
          user_ids = []

          file_path = params[:users_file][:tempfile].path
          xlsx = Roo::Spreadsheet.open file_path
          result = xlsx.sheet(0).parse

          result.each_with_index do |member_values, i|
            member_mobile = member_values.first.to_s.strip
            member = MagicBean::Member.find_by(mobile: member_mobile)
            if member
              user_ids << member.user_id
            else
              error_messages << "第#{i + 2}行: 找不到该会员"
            end
          end

          response_error(error_messages.join("; ")) if error_messages.present?

          user_ids = ((resource.user_ids || []) + user_ids).uniq
          resource.update(user_ids: user_ids)
          response_success
        rescue => e
          response_error(e.message)
        end
      end
    end
  end
end
