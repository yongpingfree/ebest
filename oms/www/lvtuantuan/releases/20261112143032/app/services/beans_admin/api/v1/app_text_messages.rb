# frozen_string_literal: true

module BeansAdmin
  class API::V1::AppTextMessages < ::API
    namespace :app_text_messages, desc: "App 内文本消息接口" do
      helpers BeansAdmin::Helpers::FileUploadHelper

      desc "批量通知用户"
      params do
        requires :file_message, type: JSON, desc: "xlsx 文件信息"
      end
      post "batch_notification" do
        response_error("请先补充 email 信息，不然没法接收通知结果") if current_admin_user.email.blank?
        response_error("请选择 xlsx 文件") unless check_file_type(params[:file_message], "xlsx")

        # 生产环境多机部署会导致后续的 job 不一定能分配到对应的服务器读取本地文件
        # 所以把文件传到 OSS
        file_path = params[:file_message]["tempfile"].path
        file_name = "app_text_messages/#{Date.current.strftime("%y%m%d")}/#{File.basename(file_path)}"
        file_url = aws_upload!(file_path, file_name)
        BatchNotifyUsersJob.perform_later(file_url, current_admin_user)

        response_success
      end
    end
  end
end
