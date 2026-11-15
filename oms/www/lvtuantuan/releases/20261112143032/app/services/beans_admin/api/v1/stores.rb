# frozen_string_literal: true
module BeansAdmin
  class API::V1::Stores < ::API

    namespace :stores, desc: "Stores API" do
      helpers do
        def permitted_params
          [:name, :is_default, :bg_color, :short_name, :default_au_suburb_id, :disabled, au_suburb_ids: [], admin_user_ids: []]
        end

        def includes
          [:default_au_suburb, :au_suburbs, [admin_users: [:admin_user_stores, :stores, :role_template]]]
        end

        def end_of_association_chain
          if params[:filter_store_id] == "true" && params[:store_id].present?
            resource_class.where(id: params[:store_id])
          else
            super
          end
        end
      end

      desc "Stores list", {
        success: API::Entities::Store,
        is_array: true
      }
      paginate
      get do
        authorize_and_response_collection(present: { with: BeansAdmin::API::Entities::Store })
      end

      desc "Create store", {
        success: API::Entities::Store
      }
      params do
        requires :all, using: API::Entities::Store.documentation.slice(:name, :bg_color, :au_suburb_ids, :admin_user_ids, :short_name)
        optional :all, using: API::Entities::Store.documentation.slice(:is_default, :disabled)
      end
      post do
        authorize_and_create_resource
      end

      route_param :id do
        desc "Store detail", {
          success: API::Entities::Store
        }
        get do
          authorize_and_response_resource
        end

        desc "Update store", {
          success: API::Entities::Store
        }
        params do
          optional :all, using: API::Entities::Store.documentation.slice(:name, :bg_color, :au_suburb_ids, :admin_user_ids, :is_default, :short_name, :disabled)
        end
        put do
          authorize_and_update_resource
        end

        desc "Destroy store", {
          success: API::Entities::SuccessfulResult
        }
        delete do
          authorize_and_destroy_resource
        end
      end
    end
  end
end
