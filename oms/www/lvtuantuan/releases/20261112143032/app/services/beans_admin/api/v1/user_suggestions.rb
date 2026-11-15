# frozen_string_literal: true
module BeansAdmin
  class API::V1::UserSuggestions < ::API

    namespace :user_suggestions, desc: "UserSuggestions API" do
      helpers do
        def permitted_params
          [:status, :reply, :member]
        end

        def includes
          [user: :member]
        end
      end

      desc "UserSuggestions list", {
        success: API::Entities::UserSuggestion,
        is_array: true
      }
      paginate
      get do
        authorize_and_response_collection
      end

      route_param :id do
        desc "UserSuggestion detail", {
          success: API::Entities::UserSuggestion
        }
        get do
          authorize_and_response_resource
        end

        desc "回复用户", {
          success: API::Entities::UserSuggestion
        }
        params do
          requires :reply, type: String
        end
        put do
          authorize_and_update_resource
        end

        desc "adopt user_suggestion", {
          success: API::Entities::SuccessfulResult
        }
        put "adopt" do
          authorize! :adopt, resource

          if resource.adopt!
            response_success
          else
            response_record_error(resource)
          end
        end

        desc "ignore user_suggestion", {
          success: API::Entities::SuccessfulResult
        }
        put "ignore" do
          authorize! :ignore, resource

          if resource.ignore!
            response_success
          else
            response_record_error(resource)
          end
        end

        desc "Destroy user_suggestion", {
          success: API::Entities::SuccessfulResult
        }
        delete do
          authorize_and_destroy_resource
        end
      end
    end
  end
end
