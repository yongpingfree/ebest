# frozen_string_literal: true

module BeansAdmin
  class API::V1::BannerClicks < ::API

    namespace :banner_clicks, desc: "图片点击 API" do
      desc "点击数据列表", {
        success: API::Entities::BannerClick,
        is_array: true
      }
      paginate
      params do
        optional :q, type: Hash do
          optional :date_gteq, type: DateTime
          optional :date_lteq, type: DateTime
          optional :count_gteq, type: Integer
          optional :count_lteq, type: Integer
        end
      end
      get do
        authorize_and_response_collection
      end

      desc "统计点击数"
      params do
        requires :q, type: Hash do
          requires :url_eq, type: String
          requires :date_gteq, type: DateTime
          requires :date_lteq, type: DateTime
        end
      end
      get :count do
        authorize! :read, MagicBean::BannerClick
        total = MagicBean::BannerClick.ransack(params[:q]).result.sum(:count)
        present total
      end
    end
  end
end
