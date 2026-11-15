# frozen_string_literal: true

module BeansAdmin
  class API::V1::ExtraOrdersLimits < ::API

    namespace :extra_orders_limits, desc: "自派配送额外订单量API" do
      helpers do
        def permitted_params
          [
            :order_amount_in_yuan, :delivery_date, :begin_at, :extra_merchant_delivery_orders_limit, :extra_merchant_delivery_total_orders_limit, :store_id
          ]
        end
      end

      desc "自派配送额外订单量列表", {
        success: API::Entities::ExtraOrdersLimit,
        is_array: true
      }
      paginate
      get do
        authorize_and_response_collection
      end

      desc "新增自派配送额外订单量", {
        success: API::Entities::ExtraOrdersLimit
      }
      params do
        requires :all, using: API::Entities::ExtraOrdersLimit.documentation.slice(
          :order_amount_in_yuan, :delivery_date, :begin_at, :extra_merchant_delivery_orders_limit, :extra_merchant_delivery_total_orders_limit
        )
      end
      post do
        authorize_and_create_resource
      end

      route_param :id do
        desc "配送额外详情", {
          success: API::Entities::ExtraOrdersLimit
        }
        get do
          authorize_and_response_resource
        end

        desc "更新配送额外", {
          success: API::Entities::ExtraOrdersLimit,
          skip_store_id: true
        }
        params do
          optional :all, using: API::Entities::ExtraOrdersLimit.documentation.slice(
            :order_amount_in_cent, :delivery_date, :begin_at, :extra_merchant_delivery_orders_limit, :extra_merchant_delivery_total_orders_limit
          )
        end
        put do
          authorize_and_update_resource
        end

        desc "删除配送额外", {
          detail: <<-NOTES.strip_heredoc
            ```json
            {
              code: 200,
              message: "ok"
            }
            ```
          NOTES
        }
        delete do
          authorize_and_destroy_resource
        end
      end
    end
  end
end
