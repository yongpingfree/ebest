# frozen_string_literal: true

module BeansAdmin
  class API::V1::SkuValues < ::API

    namespace :sku_values, desc: "SKU 规格值" do

      helpers do
        def permitted_params
          [:text]
        end
      end

      route_param :id do
        desc "编辑 SKU 规格值", {
          success: API::Entities::SkuValue
        }
        params do
          requires :all, using: API::Entities::SkuValue.documentation.dup.extract!(:text)
        end
        put do
          authorize_and_update_resource
        end
      end
    end
  end
end
