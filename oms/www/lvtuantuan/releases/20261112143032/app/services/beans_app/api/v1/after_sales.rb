# frozen_string_literal: true

module BeansApp
  class API::V1::AfterSales < ::API

    namespace :after_sales, desc: "售后 API" do

      helpers do
        def includes
          [:order, :store, after_sales_order_items: :order_item]
        end

        def permitted_params
          [:order_id, :reason, :after_sale_type, :logistic_no, :logistic_company, :additional_information, images: [], after_sales_order_items_attributes: [:quantity, :order_item_id]]
        end

        def end_of_association_chain
          current_user.after_sales
        end
      end

      desc "售后列表", {
        success: API::Entities::AfterSale,
        is_array: true
      }
      params do
        optional :status, type: String, values: MagicBean::AfterSale.statuses.keys, desc: "订单的状态"
        optional :status_in, type: Array[String],
          coerce_with: ->(val) { val.split(",").map(&:strip) },
          desc: "多状态查询",
          documentation: { param_type: "query" }
      end
      paginate
      get do
        authorize_and_response_collection
      end

      desc "新增售后", {
        success: API::Entities::AfterSale
      }
      params do
        requires :order_id, type: Integer
        requires :reason, type: String
        requires :after_sale_type, type: String
        optional :additional_information, type: String, desc: "补充信息"
        optional :images, type: Array[String]
        requires :after_sales_order_items_attributes, type: Array do
          requires :quantity, type: Integer
          requires :order_item_id, type: Integer
        end
      end
      post do
        order = MagicBean::Order.find(params[:order_id])
        error!({ error_message: "请先确认收货" }, 400) if order.wait_buyer_confirm_goods?
        authorize_and_create_resource
      end

      route_param :id do
        desc "上传退货物流信息", {
          success: API::Entities::AfterSale
        }
        params do
          requires :logistic_no, type: String, desc: "物流单号"
          requires :logistic_company, type: String, desc: "物流公司"
          optional :images, type: Array[String]
        end
        put "update_logistic_info" do
          authorize_and_run_member_action(:update_logistic_info, { present: { with_order: true }}, resource_params)
        end

        desc "售后详情", {
          success: API::Entities::AfterSale
        }
        get do
          authorize_and_response_resource({ present: { with_order: true }})
        end

        desc "取消售后退货", {
          success: API::Entities::AfterSale
        }
        put "close" do
          authorize_and_run_member_action(:close, { method: :perform_aasm_event }, :close)
        end
      end
    end
  end
end
