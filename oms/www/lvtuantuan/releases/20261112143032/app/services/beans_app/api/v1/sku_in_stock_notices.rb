# frozen_string_literal: true

module BeansApp
  class API::V1::SkuInStockNotices < ::API
    namespace :sku_in_stock_notices do
      helpers do
        def permitted_params
          [:stock_keeping_unit_id]
        end

        def build_resource
          @resource = end_of_association_chain.new(resource_params.merge(user_id: current_user.id))
        end
      end

      desc "到货通知", {
        summary: "到货通知",
        success: API::Entities::SkuInStockNotice
      }
      params do
        requires :stock_keeping_unit_id, type: Integer
      end
      post do
        build_resource

        authorize! :create, resource

        run_member_action(:generate)
      end
    end
  end
end
