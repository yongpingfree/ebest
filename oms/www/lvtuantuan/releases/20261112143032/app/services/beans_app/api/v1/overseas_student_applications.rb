# frozen_string_literal: true

module BeansApp
  class API::V1::OverseasStudentApplications < ::API
    helpers ::ApiHelpers::EmailHelper

    namespace :overseas_student_applications, desc: "留学生认证 API" do
      helpers do
        def permitted_params
          [:user_id, :nickname, :gender, :birthday, :school, :email, :student_number, :student_image_obverse_side, :student_image_reverse_side]
        end
      end

      desc "是否可申请"
      get "can_apply" do
        response_error(I18n.t("grape.student_application.already_an_overseas_student", date: current_user.overseas_student_expiration_date)) if current_user.is_overseas_student
        response_error(I18n.t("grape.student_application.application_exists")) if current_user.pending_student_application_exists?
        response_success
      end

      desc "留学生认证申请"
      params do
        requires :email, type: String, coerce_with: ->(val) { val.to_s.strip }, desc: "邮箱"
        requires :code, type: String, desc: "验证码"
        requires :nickname, type: String, desc: "昵称"
        requires :gender, type: String, values: MagicBean::OverseasStudentApplication.genders.keys, desc: "性别"
        requires :school, type: String, desc: "学校"
        requires :student_number, type: String, desc: "学生证"
        requires :student_image_obverse_side, type: String, desc: "学生证正面"
        optional :student_image_reverse_side, type: String, desc: "学生证反面"
        optional :birthday, type: Date, desc: "生日"
      end
      post do
        check_email!(params[:email], :overseas_student_auth)
        check_email_verification_code!(params[:email], params[:code], :overseas_student_auth)
        response_error(I18n.t("grape.student_application.already_an_overseas_student", date: current_user.overseas_student_expiration_date)) if current_user.is_overseas_student
        response_error(I18n.t("grape.student_application.application_exists")) if current_user.pending_student_application_exists?
        application = current_user.overseas_student_applications.new(resource_params)
        standard_save(application, collection_entity)
      end

      desc "最新通过认证的信息", {
        success: API::Entities::OverseasStudentApplication
      }
      get :newest_agreed do
        resource = current_user.overseas_student_applications.agreed.order(created_at: :asc).last
        if resource.present?
          present resource, with: API::Entities::OverseasStudentApplication
        else
          raise ActiveRecord::RecordNotFound
        end
      end
    end
  end
end
