# frozen_string_literal: true

module BeansAdmin
  class API::V1::MarketingMessages < ::API

    namespace "marketing_messages", desc: "营销短信接口" do
      helpers BeansAdmin::Helpers::FileUploadHelper
      helpers do
        def includes
          [:admin_user, :store]
        end

        def format_template_users(rows)
          rows.map { |id, nickname, mobile| { id: id, nickname: nickname, member_mobile: mobile } }
        end

        def permitted_params
          [:content, :state, :store_id, :admin_user_id, :push_at, :sms_platform, user_ids: [], manual_user_ids: []]
        end
      end

      desc "营销短信列表", {
        success: API::Entities::MarketingMessage,
        is_array: true,
      }
      paginate
      get do
        authorize_and_response_collection
      end

      desc "查询用户模板列表"
      get "user_query_templates" do
        authorize! :read, MagicBean::MarketingMessage
        { data: MagicBean::MarketingMessage::USER_QUERY_TEMPLATES.map { |key, template| { value: key.to_s, label: template[:label] } } }
      end

      desc "按模板加载用户列表", {
        detail: "返回 nickname + 手机号, 仅供选择名单使用"
      }
      params do
        requires :template, type: String, values: MagicBean::MarketingMessage::USER_QUERY_TEMPLATES.keys.map(&:to_s), desc: "查询用户模板"
      end
      get "template_users" do
        authorize! :read, MagicBean::MarketingMessage

        rows = MagicBean::MarketingMessage.template_users(params[:template], store_id: current_store_id)
          .order("users.id")
          .pluck("users.id", "users.nickname", "members.mobile")

        { data: { total: rows.size, users: format_template_users(rows) } }
      end

      desc "创建营销短信", {
        success: API::Entities::MarketingMessage
      }
      params do
        requires :all, using: API::Entities::MarketingMessage.documentation.dup.extract!(:content, :push_at, :state)
      end
      post do
        params[:store_id] = current_store_id
        params[:admin_user_id] = current_admin_user.id
        authorize_and_create_resource
      end

      route_param :id do
        desc "消息中心详情", {
          success: API::Entities::MarketingMessage
        }
        get do
          authorize_and_response_resource
        end

        desc "消息指定用户名单"
        get "users" do
          authorize! :read, resource

          rows = MagicBean::User.where(id: resource.user_ids)
            .joins(:member)
            .order("users.id")
            .pluck("users.id", "users.nickname", "members.mobile")

          { data: format_template_users(rows) }
        end

        desc "修改营销短信", {
          success: API::Entities::MarketingMessage
        }
        params do
          optional :all, using: API::Entities::MarketingMessage.documentation.dup.extract!(:content, :push_at, :state, :user_ids, :manual_user_ids)
        end
        put do
          authorize_and_update_resource
        end

        desc "删除营销短信", {
          success: API::Entities::MarketingMessage
        }
        delete do
          authorize_and_destroy_resource
        end

        desc "导入指定用户", {
          detail: <<-NOTES.strip_heredoc
            导入的用户计入「手动添加用户」名单(manual_user_ids), 发送时与模板名单合并去重。
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
              # 发送时只发给消息所属门店的用户, 非该门店的导入后也不会发送, 直接提示
              if member.user&.selected_store_id == resource.store_id
                user_ids << member.user_id
              else
                error_messages << "第#{i + 2}行: 该用户不属于当前门店"
              end
            else
              error_messages << "第#{i + 2}行: 找不到该会员"
            end
          end

          response_error(error_messages.join("; ")) if error_messages.present?

          imported_ids = ((resource.manual_user_ids || []) + user_ids).uniq
          resource.update(manual_user_ids: imported_ids)
          response_success
        rescue => e
          response_error(e.message)
        end
      end
    end
  end
end
