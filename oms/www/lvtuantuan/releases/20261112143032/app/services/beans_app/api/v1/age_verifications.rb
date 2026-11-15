# frozen_string_literal: true

module BeansApp
  class API::V1::AgeVerifications < ::API
    namespace :age_verifications, desc: "年龄验证API" do
      helpers do
        def includes
          [:translations]
        end
      end

      route_param :parent_category_id do
        helpers do
          def resource
            @resource ||= if params[:category_type] == "app"
                            MagicBean::AgeVerification.find_by(parent_category_id: params[:parent_category_id])
                          else
                            MagicBean::AgeVerification.find_by(parent_web_category_id: params[:parent_category_id])
                          end
          end
        end

        desc "详情", {
          success: API::Entities::AgeVerification,
          skip_authentication: true
        }
        params do
          optional :category_type, type: String, values: %w[web app], default: "app", desc: "分类类型"
        end
        get do
          response_resource
        end
      end
    end
  end
end
