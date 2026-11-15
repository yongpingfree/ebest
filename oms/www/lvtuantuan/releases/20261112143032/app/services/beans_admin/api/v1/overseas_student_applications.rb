# frozen_string_literal: true

module BeansAdmin
  class API::V1::OverseasStudentApplications < ::API

    namespace :overseas_student_applications, desc: "留学生认证申请 API" do
      desc "申请列表", {
        success: API::Entities::OverseasStudentApplication,
        is_array: true
      }
      paginate
      get do
        authorize_and_response_collection
      end

      route_param :id do
        desc "申请详情", {
          success: API::Entities::OverseasStudentApplication
        }
        get do
          authorize_and_response_resource
        end

        desc "申请操作", {
          success: API::Entities::SuccessfulResult
        }
        params do
          requires :action, type: String, values: ["agree", "refuse"]
        end

        put "process" do
          authorize! :update, resource

          if resource.send("#{params[:action]}!")
            response_success
          else
            response_record_error(resource)
          end
        end
      end
    end
  end
end
