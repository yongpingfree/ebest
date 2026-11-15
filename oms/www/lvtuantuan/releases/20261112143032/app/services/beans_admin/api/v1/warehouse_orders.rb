# frozen_string_literal: true

module BeansAdmin
  class API::V1::WarehouseOrders < ::API
    namespace :warehouse_orders, desc: "仓储订单接口" do
      helpers ::BeansAdmin::Helpers::OrderChannelPermissionHelper
      helpers do
        def default_order
          "warehouse_orders.created_at desc"
        end

        def end_of_association_chain
          channel_permission_values = calculate_order_channel_permissions(current_admin_user) + ["shopline"]
          @end_of_association_chain ||= resource_class.where(channel: channel_permission_values)
        end

        def includes
          [:user, :store, :orders, :shopline_orders]
        end
      end

      desc "订单列表", {
        success: API::Entities::WarehouseOrder,
        is_array: true
      }
      paginate
      params do
        optional :created_at_gteq, type: DateTime
        optional :created_at_lteq, type: DateTime
        optional :delivery_type_eq, values: -> { ::MagicBean::WarehouseOrder.delivery_types.keys }
        optional :delivery_date_gteq, type: Date
        optional :delivery_date_lteq, type: Date
      end
      get do
        authorize_and_response_collection
      end

      route_param :id do
        desc "订单详情", {
          success: API::Entities::WarehouseOrder
        }
        get do
          authorize_and_response_resource
        end
      end
    end
  end
end
