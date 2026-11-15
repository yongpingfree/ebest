# frozen_string_literal: true

module BeansAdmin
  class API::V1::SkuReturns < ::API
    helpers ::BeansAdmin::Helpers::SkuSalesHelper

    namespace :sku_returns, desc: "商品退货统计" do
      helpers do
        def collection_entity
          @collection_entity ||= BeansAdmin::API::Entities::StockKeepingUnit
        end

        def resource_class
          MagicBean::StockKeepingUnit
        end

        def includes
          [:item]
        end
      end

      desc "SKU 退货列表", {
        success: API::Entities::SkuReturn,
        is_array: true
      }
      paginate
      params do
        optional :after_sale_agreed_at_gteq, type: Date
        optional :after_sale_agreed_at_lteq, type: Date
        optional :order_by, type: String, values: ["sum_after_sale_in_yuan asc", "sum_after_sale_in_yuan desc", "sum_after_sale_quantity asc", "sum_after_sale_quantity desc"]
      end
      get do
        raise CanCan::AccessDenied unless current_user.permissions.include?("sku_returns")
        order_by = ::BeansAdmin::Helpers::OrderBySanitizer.sanitize(params[:order_by] || default_order)
        order_by = default_order if order_by.blank?
        params["item_parent_category_id_in"] = current_user.can_read_category_ids
        sku_returns_collection(params, order_by, current_store_id, current_user)
        response_collection({ present: { with: API::Entities::SkuReturn } })
      end

      desc "导出SKU 退货列表"
      params do
        optional :after_sale_agreed_at_gteq, type: Date
        optional :after_sale_agreed_at_lteq, type: Date
      end
      get "export" do
        raise CanCan::AccessDenied unless current_user.permissions.include?("sku_returns")
        response_error("您还没有设置邮箱。") if current_admin_user.email.blank?
        check_export_list_count

        order_by = ::BeansAdmin::Helpers::OrderBySanitizer.sanitize(params[:order_by] || default_order)
        order_by = default_order if order_by.blank?
        params["item_parent_category_id_in"] = current_user.can_read_category_ids

        options = {
          user_id: current_admin_user.id,
          email: current_admin_user.email,
          params: params,
          store_id: current_store_id,
          order_by: order_by
        }

        options = encrypt_params(options)

        ExportSkuReturnJob.perform_later(options)

        present({ message: "导出任务后台执行，请稍后查看邮箱。" })
      end
    end
  end
end
