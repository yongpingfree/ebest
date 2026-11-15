# frozen_string_literal: true

module BeansAdmin
  class API::V1::ThirdPartyOrders < ::API
    namespace :third_party_orders, desc: "第三方订单接口" do
      helpers do
        def default_order
          "third_party_orders.created_at desc"
        end

        def includes
          [:store, :warehouse_order]
        end

        def permitted_params
          [:delivery_date, :prefer_time]
        end
      end

      desc "订单列表", {
        success: API::Entities::ThirdPartyOrder,
        is_array: true
      }
      paginate
      params do
        optional :created_at_gteq, type: DateTime
        optional :created_at_lteq, type: DateTime
        optional :delivery_type_eq, values: -> { ::MagicBean::ThirdPartyOrder.delivery_types.keys }
        optional :delivery_date_gteq, type: Date
        optional :delivery_date_lteq, type: Date
      end
      get do
        authorize_and_response_collection
      end

      desc "创建Shopline订单", {
        success: API::Entities::ThirdPartyOrder
      }
      paginate
      params do
        requires :no, type: String
      end
      post "shopline" do
        # 不单独设置创建权限，有读取权限就可操作（本义上不算创建，只是操作同步shopline订单）
        authorize! :read, resource_class
        
        current_store = MagicBean::Store.find current_store_id
        message, order = MagicBean::ThirdPartyOrder.create_shopline_order(params[:no]&.strip, current_store.peti_store?, current_store.site_config, "admin")

        if message == "success"
          present order, with: ::BeansAdmin::API::Entities::ThirdPartyOrder
        else
          response_error(message)
        end
      end

      desc "批量确认订单", {
        success: API::Entities::SuccessfulResult
      }
      params do
        requires :order_ids, type: Array[Integer], coerce_with: ->(val) { val.split(/[,]/).map(&:strip).map(&:to_i) }
      end
      put "batch_confirm" do
        response_error "请选择可确认的订单" if params[:order_ids].blank?
        confirm_nos = []
        MagicBean::ThirdPartyOrder.where(id: params[:order_ids]).each do |order|
          if order.pending?
            order.confirmed!
            confirm_nos << order.no
          end
        end

        if confirm_nos.present?
          log_message = "批量确认第三方订单，订单号: #{confirm_nos.join("，")}"
          current_admin_user.operation_records.create(content: log_message, store_id: current_store_id)
        end

        response_success
      end

      route_param :id do
        desc "订单详情", {
          success: API::Entities::ThirdPartyOrder
        }
        get do
          authorize_and_response_resource
        end

        desc "回退库存（仅全部退款订单可操作）", {
          success: API::Entities::ThirdPartyOrder
        }
        put "return_inventory" do
          authorize! :return_inventory, resource
          response_error("该订单不可回退库存") unless resource.can_return_inventory?
          
          MagicBean::StockKeepingUnit.transaction do
            resource.refunds.each do |refund|
              refund["refund_line_items"].each do |item|
                next unless item["restock_type"] == "return"

                sku = MagicBean::StockKeepingUnit.find_by(no: item["line_item"]["sku"], store_id: resource.store_id)
                sku&.increase_inventory!(item["quantity"])
              end
            end

            resource.update!(inventory_returned: true)
          end

          response_success
        end

        desc "手动生成仓储订单", {
          success: API::Entities::Order
        }
        post "warehouse_orders" do
          authorize! :update, resource

          if resource.can_create_warehouse_order? && resource.shopline?
            resource.generate_shopline_warehouse_order
            response_resource
          else
            response_error(I18n.t("error.order.wrong_status_to_create_warehouse_order"))
          end
        end

        desc "编辑订单配送时间", {
          success: API::Entities::Order
        }
        params do
          optional :delivery_date, type: String, desc: "预计发货日期"
          optional :prefer_time, type: String, desc: "预计发货时间"
        end
        put "delivery_message" do
          log_messages = []
          log_messages << "将发货日期#{resource.delivery_date}改为#{params[:delivery_date]}" if params[:delivery_date].present? && resource.delivery_date != params[:delivery_date]
          log_messages << "将发货时间#{resource.prefer_time}改为#{params[:prefer_time]}" if params[:prefer_time].present? && resource.prefer_time != params[:prefer_time]

          # 前端会传prefer_time过来，但值为空，导致订单的prefer_time被清空
          params.delete(:prefer_time) if params[:prefer_time].nil?

          authorize! :update, resource

          if resource.update(resource_params)
            current_admin_user.operation_records.create(operatable: resource, content: log_messages.join(", "), store_id: current_store_id) if log_messages.present?
            
            response_resource
          else
            response_record_error(resource)
          end
        end
      end
    end
  end
end
