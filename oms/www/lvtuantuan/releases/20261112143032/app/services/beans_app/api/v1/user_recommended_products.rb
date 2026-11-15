# frozen_string_literal: true

module BeansApp
  class API::V1::UserRecommendedProducts < ::API

    namespace :user_recommended_products, desc: "UserRecommendedProducts API" do

      helpers do
        def permitted_params
          [:recommended_products, :mobile, :wechat, images: []]
        end

        def end_of_association_chain
          current_user.user_recommended_products
        end
      end

      desc "创建好物推荐", {
        success: API::Entities::UserRecommendedProduct
      }
      params do
        requires :recommended_products, type: String, desc: "推荐商品内容"
        optional :mobile, type: String, desc: "手机号"
        optional :wechat, type: String, desc: "微信号"
        optional :images, type: Array[String]
      end
      post do
        # 避免恶意攻击，限制用户每天不能超过100条
        if current_user.user_recommended_products.where("created_at >= ?", Time.current.beginning_of_day).count >= 100
          response_error(I18n.t("grape.user_recommended_products.times_limit"))
        end
        authorize_and_create_resource
      end
    end
  end
end
