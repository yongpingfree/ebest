# frozen_string_literal: true

module BeansApp
  class API::V1::UserSuggestions < ::API

    namespace :user_suggestions, desc: "UserSuggestions API" do

      helpers do
        def permitted_params
          [:content, :channel, images: []]
        end

        def end_of_association_chain
          current_user.user_suggestions
        end
      end

      desc "用户反馈列表", {
        success: API::Entities::UserSuggestion,
        is_array: true
      }
      paginate
      get do
        authorize_and_response_collection
      end

      desc "创建用户建议", {
        success: API::Entities::UserSuggestion
      }
      params do
        requires :content, type: String, desc: "内容"
        optional :images, type: Array[String]
      end
      post do
        params[:channel] = ebest_channel
        authorize_and_create_resource
      end
    end
  end
end
