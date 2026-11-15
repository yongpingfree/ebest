# frozen_string_literal: true
module BeansAdmin
  class API::V1::AdminAssignIntegralRecords < ::API

    namespace :admin_assign_integral_records, desc: "管理员发放积分记录 API" do
      helpers BeansAdmin::Helpers::FileUploadHelper
      helpers do
        def includes
          [:member, :admin_user]
        end

        def permitted_params
          [:member_id, :admin_user_id, :store_id, :content, :integral]
        end
      end
      desc "管理员发放积分记录 列表", {
        success: API::Entities::AdminAssignIntegralRecord,
        is_array: true
      }
      paginate
      get do
        authorize_and_response_collection
      end

      desc "管理员发放积分接口", {
        success: API::Entities::AdminAssignIntegralRecord
      }
      params do
        requires :member_id, type: Integer, desc: "会员ID"
        requires :integral, type: Integer, desc: "积分"
      end
      post do
        build_resource
        resource.content = "发放了#{params[:integral]}积分"
        resource.store_id = current_store_id
        resource.admin_user_id = current_user.id
        authorize! :create, resource
        run_member_action(:create, { method: :save }, resource_params)
      end

      desc "管理员导入发放积分接口"
      params do
        requires :file_message, type: JSON, desc: "xlsx 文件信息"
      end
      post "import" do
        response_error("请选择 xlsx 文件") unless check_file_type(params[:file_message], "xlsx")

        xlsx = Roo::Spreadsheet.open params[:file_message]["tempfile"].path
        result = xlsx.sheet(0).parse

        import_errors = []
        MagicBean::AdminAssignIntegralRecord.transaction do
          result.each_with_index do |integral_values, i|
            error_messages = []
            mobile, integral = integral_values
            member = MagicBean::Member.find_by(mobile: mobile)
            error_messages << "#{mobile} 找不到此会员" if member.blank?
            error_messages << "积分须为正数" unless integral.to_i.positive?

            if error_messages.present?
              import_errors << "第#{i + 2}行: #{error_messages.join("，")}"
              next
            end

            content = "导入发放了#{params[:integral]}积分"

            record = end_of_association_chain.new(
              {
                integral: integral,
                content: content,
                admin_user_id: current_user.id,
                member_id: member.id,
                store_id: current_store_id
              }
            )

            import_errors << "第#{i + 2}行: #{record.errors.full_messages.join("，")}" unless record.save
          end

          raise ActiveRecord::RecordInvalid if import_errors.present?
        end
        response_success
      rescue ActiveRecord::RecordInvalid => e
        response_error(import_errors.join("; "))
      rescue => e
        response_error(e.message)
      end

      route_param :id do
        desc "管理员发放积分记录 详情", {
          success: API::Entities::AdminAssignIntegralRecord
        }
        get do
          authorize_and_response_resource
        end
      end
    end
  end
end
