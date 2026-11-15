# frozen_string_literal: true

module BeansApp
  class API::V1::Invoices < ::API
    namespace :invoices, desc: "发票 API" do
      helpers do
        def permitted_params
          [:title, :abn, :first_name, :last_name, :tel_number, :address, :email, :alias_name, :is_default, :kind]
        end

        def end_of_association_chain
          current_user.invoices
        end
      end

      desc "发票列表", {
        success: API::Entities::Invoice,
        is_array: true
      }
      paginate
      get do
        authorize_and_response_collection
      end

      desc "创建发票", {
        success: API::Entities::Invoice
      }
      params do
        requires :all, using: API::Entities::Invoice.documentation.slice(:first_name, :last_name, :email) # TODO: app 上线后增加 kind 必填校验
        optional :all, using: API::Entities::Invoice.documentation.slice(:title, :abn, :tel_number, :address, :is_default)
      end
      post do
        authorize_and_create_resource
      end

      desc "获取默认发票", {
        summary: "获取默认发票",
        success: API::Entities::Invoice
      }
      get "default" do
        @resource = end_of_association_chain.find_by!(is_default: true)

        authorize_and_response_resource
      end

      route_param :id do
        desc "发票详情", {
          success: API::Entities::Invoice
        }
        get do
          authorize_and_response_resource
        end

        desc "更新发票", {
          success: API::Entities::Invoice
        }
        params do
          optional :all, using: API::Entities::Invoice.documentation.slice(:title, :first_name, :last_name, :email, :kind, :abn, :tel_number, :address, :is_default)
        end
        put do
          authorize_and_update_resource
        end

        desc "删除发票", {
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
          authorize_and_destroy_resource
        end
      end
    end
  end
end
