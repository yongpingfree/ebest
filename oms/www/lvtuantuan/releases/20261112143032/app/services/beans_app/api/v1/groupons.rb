# frozen_string_literal: true

module BeansApp
  class API::V1::Groupons < ::API

    namespace :groupons, desc: "拼团接口" do
      helpers do
        def collection_search_sentence
          groupons = params[:kind] ? "#{params[:kind]}_groupons" : "groupons"
          @collection = current_user.public_send(groupons).includes(includes).accessible_by(current_ability).ransack(ransack_params)
        end

        def includes
          [:groupon_activity]
        end
      end

      desc "拼团列表", {
        success: API::Entities::SimpleGroupon,
        is_array: true,
        skip_authentication: true
      }
      params do
        requires :groupon_activity_id, desc: "拼团活动ID"
      end
      paginate
      get "waiting_groupons" do
        groupons = MagicBean::GrouponActivity.find(params[:groupon_activity_id]).waiting_groupons
        present paginate(groupons), with: API::Entities::SimpleGroupon, current_user: current_user
      end

      desc "我的拼团列表", {
        success: API::Entities::SimpleGroupon,
        is_array: true
      }
      params do
        optional :kind, values: ["created", "joined"], desc: "created: 发起的拼团; joined: 参与的拼团"
      end
      paginate
      get do
        authorize_and_response_collection(params: { current_user: current_user })
      end

      route_param :id do
        desc "拼团详情", {
          success: API::Entities::Groupon,
          is_array: true,
          skip_authentication: true
        }
        get do
          authorize_and_response_resource(params: { current_user: current_user })
        end
      end
    end
  end
end
