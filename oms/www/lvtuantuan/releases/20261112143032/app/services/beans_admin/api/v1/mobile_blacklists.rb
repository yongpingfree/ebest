# frozen_string_literal: true

module BeansAdmin
  class API::V1::MobileBlacklists < ::API
    namespace :mobile_blacklists, desc: "电话黑名单接口" do
      helpers BeansAdmin::Helpers::FileUploadHelper
      helpers do
        def permitted_params
          [:mobile, :enabled, :live_comment_disabled, :live_lottery_disabled, :order_disabled, :started_at, :ended_at, :push_notification_disabled, :marketing_sms_disabled]
        end
      end

      desc "黑名单列表", {
        success: API::Entities::MobileBlacklist,
        is_array: true,
        skip_store_id_filter: true
      }
      paginate
      params do
        optional :mobile_cont, type: String, desc: "手机号"
      end
      get do
        authorize_and_response_collection
      end

      desc "创建黑名单", {
        success: API::Entities::MobileBlacklist
      }
      params do
        requires :all, using: API::Entities::MobileBlacklist.documentation.dup.extract!(:mobile, :enabled, :live_comment_disabled, :live_lottery_disabled, :order_disabled, :push_notification_disabled, :marketing_sms_disabled)
        optional :all, using: API::Entities::MobileBlacklist.documentation.dup.extract!(:started_at, :ended_at)
      end
      post do
        authorize_and_create_resource
      end

      desc "异步导入黑名单"
      params do
        requires :file_message, type: JSON, desc: "xlsx 文件信息"
      end
      post "async_import" do
        response_error("请选择 xlsx 文件") unless check_file_type(params[:file_message], "xlsx")

        file_path = params[:file_message]["tempfile"].path
        file_name = "mobile_blacklists/#{Date.current.strftime("%y%m%d")}/#{File.basename(file_path)}"
        file_url = aws_upload!(file_path, file_name)

        ImportFromExcelAndNotifyJob.perform_later("MagicBean::MobileBlacklist", file_url, current_admin_user.id)

        response_success
      end

      route_param :id do
        desc "详情", {
          success: API::Entities::MobileBlacklist
        }
        get do
          authorize_and_response_resource
        end

        desc "修改信息", {
          success: API::Entities::MobileBlacklist
        }
        params do
          optional :all, using: API::Entities::MobileBlacklist.documentation.dup.extract!(:mobile, :enabled, :live_comment_disabled, :live_lottery_disabled, :order_disabled, :started_at, :ended_at, :push_notification_disabled, :marketing_sms_disabled)
        end
        put do
          authorize_and_update_resource
        end

        desc "删除黑名单", {
          success: API::Entities::SuccessfulResult
        }
        delete do
          authorize_and_destroy_resource
        end
      end
    end
  end
end
