# frozen_string_literal: true

module BeansAdmin
  class API::V1::ReportPages < ::API
    namespace :report_pages, desc: "报表页面 API" do
      helpers do
        def permitted_params
          [:name, :content, :creator_id, admin_user_ids: []]
        end

        def includes
          [:creator]
        end
      end

      desc "报表页面列表", {
        success: API::Entities::ReportPage,
        is_array: true
      }
      paginate
      get do
        authorize_and_response_collection
      end

      desc "报表预览列表", {
        success: API::Entities::ReportPage,
        is_array: true
      }
      paginate
      get "preview_list" do
        raise CanCan::AccessDenied unless current_user.permissions.include?("report_pages_preview")
        # 只获取自己创建、可预览的管理员包含自己、可预览的管理员为空的报表页面
        pages = MagicBean::ReportPage.where(creator_id: current_user.id).or(MagicBean::ReportPage.where("admin_user_ids @> ARRAY[?]::integer[]", [current_user.id])).or(MagicBean::ReportPage.where(admin_user_ids: []))
        present paginate(pages), with: API::Entities::ReportPage
      end

      desc "新增报表页面", {
        success: API::Entities::ReportPage
      }
      params do
        requires :name, type: String, desc: "页面名"
        requires :content, type: String, desc: "内容"
      end
      post do
        params[:creator_id] = current_user.id
        authorize_and_create_resource
      end

      route_param :id do
        desc "报表页面详情", {
          success: API::Entities::ReportPage
        }
        get do
          authorize_and_response_resource
        end

        desc "更新报表页面", {
          success: API::Entities::ReportPage
        }
        params do
          optional :name, type: String, desc: "页面名"
          optional :content, type: String, desc: "内容"
        end
        put do
          response_error("仅创建者可修改该报表") if current_user.id != resource.creator_id
          authorize_and_update_resource
        end

        desc "删除报表页面", {
          success: API::Entities::SuccessfulResult
        }
        delete do
          response_error("仅创建者可删除该报表") if current_user.id != resource.creator_id
          authorize_and_destroy_resource
        end
      end
    end
  end
end
