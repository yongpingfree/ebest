# frozen_string_literal: true

module BeansApp
  class API::V1::Auction::ActivityParticipations < ::API
    namespace :auction_activity_participations, desc: "我的拍卖 API" do
      helpers do
        def end_of_association_chain
          current_user.auction_activity_participations
        end

        def resource_class
          MagicBean::Auction::ActivityParticipation
        end

        def collection_entity
          BeansApp::API::Entities::Auction::ActivityParticipation
        end

        def entity_namespace_name
          "BeansApp::API::Entities::Auction".freeze
        end
      end

      desc "拍卖列表", {
        success: API::Entities::Auction::ActivityParticipation,
        is_array: true
      }
      paginate
      params do
        optional :state_eq, type: String, desc: "拍卖状态"
      end
      get do
        authorize_and_response_collection
      end

      desc "通过 auction_activity_id 获取参与记录详情", {
        success: API::Entities::Auction::ActivityParticipation
      }
      params do
        requires :auction_activity_id, type: String, desc: "拍卖活动ID"
      end
      get :by_activity do
        participation = end_of_association_chain.find_by!(auction_activity_id: params[:auction_activity_id])

        present participation, with: API::Entities::Auction::ActivityParticipation
      end

      route_param :id do
        desc "拍卖参与记录详情", {
          success: API::Entities::Auction::ActivityParticipation
        }
        get do
          authorize_and_response_resource
        end
      end
    end
  end
end
