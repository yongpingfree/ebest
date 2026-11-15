# frozen_string_literal: true

module BeansAdmin
  class API::V1::StockKeepingUnits < ::API
    helpers ::BeansAdmin::Helpers::SkuSalesHelper

    namespace :stock_keeping_units, desc: "商品列表" do
      helpers do
        def collection_entity
          @collection_entity ||= BeansAdmin::API::Entities::StockKeepingUnit
        end

        def includes
          [item: [:translations, :store, :shopline_item, :product, :category, :minor_category, :web_category, :minor_web_category, brand: [:translations]]]
        end
      end
      desc "SKU 列表"
      params do
        optional :item_title_or_item_sub_title_cont
        optional :barcode_or_no_cont
        optional :item_category_id_eq, type: Integer
        optional :item_parent_category_id_eq, type: Integer
        optional :item_minor_category_id_eq, type: Integer
        optional :pending_in_stock_notices_count_gteq, type: Integer
        optional :notice_created_at_gteq, type: DateTime
        optional :notice_created_at_lteq, type: DateTime
        optional :item_ae_drop_shipper_eq, type: Boolean, default: false, desc: "是否是跨境购"
      end
      paginate
      get do
        params["item_parent_category_id_in"] = current_user.can_read_category_ids
        params["item_item_type_not_eq"] = :auction # 过滤掉拍卖 SKU

        if params["pending_in_stock_notices_count_gteq"]
          raise CanCan::AccessDenied unless current_user.permissions.include?("sku_in_stock_notices")
          # 如果选了时间范围，才需要查询pending_notice_hash
          pending_notice_hash = nil
          pending_notice_hash = MagicBean::SkuInStockNotice.pending.ransack({ created_at_gteq: params[:notice_created_at_gteq], created_at_lteq: params[:notice_created_at_lteq] }).result.group(:stock_keeping_unit_id).count if params[:notice_created_at_gteq].present? || params[:notice_created_at_lteq].present?

          response_collection(params: { pending_notice_hash: pending_notice_hash })
        else
          authorize_and_response_collection
        end
      end

      desc "SKU搜索列表，方便后端活动配置搜索"
      params do
        optional :no_or_item_translated_searchable_title_cont
        optional :barcode_or_no_cont
        optional :item_category_id_eq, type: Integer
        optional :item_parent_category_id_eq, type: Integer
        optional :item_minor_category_id_eq, type: Integer
        optional :item_ae_drop_shipper_eq, type: Boolean, default: false, desc: "是否是跨境购"
      end
      paginate
      get "search" do
        skus = MagicBean::StockKeepingUnit.includes(item: :translations).ransack(ransack_params).result.order(default_order)
        present paginate(skus), with: BeansAdmin::API::Entities::MinimalStockKeepingUnit
      end

      desc "导出SKU Sales列表"
      params do
        optional :order_created_at_gteq, type: Date
        optional :order_created_at_lteq, type: Date
        optional :order_delivery_date_gteq, type: Date
        optional :order_delivery_date_lteq, type: Date
        optional :ae_drop_shipper, type: Boolean, default: false, desc: "是否是跨境购"
      end
      get "sales_export" do
        raise CanCan::AccessDenied unless current_user.permissions.include?("sku_sales")
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

        ExportSalesJob.perform_later(options)

        present({ message: "导出任务后台执行，请稍后查看邮箱。" })
      end

      desc "SKU供应商列表", {
        success: API::Entities::SkuWithSupplier,
        is_array: true
      }
      paginate
      params do
        optional :order_by, type: String, values: ["quantity asc", "quantity desc"]
        optional :ae_drop_shipper, type: Boolean, default: false, desc: "是否是跨境购"
      end
      get "suppliers" do
        raise CanCan::AccessDenied unless current_user.permissions.include?("sku_suppliers")
        order_by = ::BeansAdmin::Helpers::OrderBySanitizer.sanitize(params[:order_by] || default_order)
        order_by = default_order if order_by.blank?
        params["item_parent_category_id_in"] = current_user.can_read_category_ids
        sales_supplier_collections(params, order_by, current_store_id)

        response_collection({ present: { with: API::Entities::SkuWithSupplier } })
      end

      desc "SKU供应商列表", {
        success: API::Entities::SkuWithSupplier,
        is_array: true
      }
      paginate
      params do
        optional :order_by, type: String, values: ["quantity asc", "quantity desc"]
        optional :ae_drop_shipper, type: Boolean, default: false, desc: "是否是跨境购"
      end
      get "suppliers_export" do
        raise CanCan::AccessDenied unless current_user.permissions.include?("sku_suppliers")
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

        ExportSkuSuppliersJob.perform_later(options)

        present({ message: "导出任务后台执行，请稍后查看邮箱。" })
      end

      desc "SKU sales 列表", {
        success: API::Entities::SkuSale,
        is_array: true
      }
      paginate
      params do
        optional :order_created_at_gteq, type: Date
        optional :order_created_at_lteq, type: Date
        optional :order_delivery_date_gteq, type: Date
        optional :order_delivery_date_lteq, type: Date
        optional :custom_list_id, type: Integer
        optional :order_by, type: String, values: ["sales_count asc", "sales_count desc", "sum_price_in_yuan asc", "sum_price_in_yuan desc"]
        optional :ae_drop_shipper, type: Boolean, default: false, desc: "是否是跨境购"
      end
      get "sales" do
        raise CanCan::AccessDenied unless current_user.permissions.include?("sku_sales")
        order_by = ::BeansAdmin::Helpers::OrderBySanitizer.sanitize(params[:order_by] || default_order)
        order_by = default_order if order_by.blank?
        params["item_parent_category_id_in"] = current_user.can_read_category_ids
        sales_collections(params, order_by, current_store_id, current_user)
        sku_return_hash = sales_collections_returns_data(paginate(collection).map(&:id), params, current_user)
        shopline_sale_and_refund_hash = shopline_sku_sales_collections(params, current_store_id, current_user)

        response_collection({ present: { with: API::Entities::SkuSale, sku_return_hash: sku_return_hash, shopline_sale_and_refund_hash: shopline_sale_and_refund_hash } })
      end

      desc "计划销量", {
        success: API::Entities::SkuSale,
        is_array: true
      }
      paginate
      params do
        optional :order_created_at_gteq, type: Date
        optional :order_created_at_lteq, type: Date
        requires :recommended_restocking_point, type: Integer, desc: "建议补货点"
        requires :recommended_restocking_upper_limit, type: Integer, desc: "建议补货上限"
        # FIXME: item_title_cont查询条件失效，需要修复
        optional :item_title_cont, type: String, desc: "标题"
        optional :catetory_ids, type: Array[Integer], desc: "分类数组"
        optional :supplier_name_cont, type: String, desc: "供应商名字"
        optional :shoppingunit_cont, type: String, desc: "入驻商名字"
        optional :order_by, type: String, values: ["quantity asc", "quantity desc"]
        optional :ae_drop_shipper, type: Boolean, default: false, desc: "是否是跨境购"
      end
      get "sales_plan" do
        raise CanCan::AccessDenied unless current_user.permissions.include?("sku_sales_plan")
        order_by = ::BeansAdmin::Helpers::OrderBySanitizer.sanitize(params[:order_by] || default_order)
        order_by = default_order if order_by.blank?
        params["item_parent_category_id_in"] = current_user.can_read_category_ids

        validate_export_date_params(
          params[:order_created_at_gteq],
          params[:order_created_at_lteq],
          false
        )
        sales_plan_collections(params, order_by, current_store_id)
        sku_valid_inventory_dates_hash = sales_plan_sku_valid_inventory_dates_hash(params, current_store_id)
        reserved_quantity_hash = sku_reserved_quantity_hash(current_store_id)
        response_collection(present: { with: API::Entities::SkuSalePlan, recommended_restocking_point: params[:recommended_restocking_point], recommended_restocking_upper_limit: params[:recommended_restocking_upper_limit], sku_valid_inventory_dates_hash: sku_valid_inventory_dates_hash, reserved_quantity_hash: reserved_quantity_hash })
      end

      desc "导出计划销量列表"
      params do
        optional :order_created_at_gteq, type: Date
        optional :order_created_at_lteq, type: Date
        requires :recommended_restocking_point, type: Integer, desc: "建议补货点"
        requires :recommended_restocking_upper_limit, type: Integer, desc: "建议补货上限"
        optional :item_title_cont, type: String, desc: "标题"
        optional :catetory_ids, type: Array[Integer], desc: "分类数组"
        optional :supplier_name_cont, type: String, desc: "供应商名字"
        optional :ae_drop_shipper, type: Boolean, default: false, desc: "是否是跨境购"
      end
      get "sales_plan_export" do
        raise CanCan::AccessDenied unless current_user.permissions.include?("sku_sales_plan")
        response_error("您还没有设置邮箱。") if current_admin_user.email.blank?

        check_export_list_count

        order_by = ::BeansAdmin::Helpers::OrderBySanitizer.sanitize(params[:order_by] || default_order)
        order_by = default_order if order_by.blank?
        params["item_parent_category_id_in"] = current_user.can_read_category_ids

        validate_export_date_params(
          params[:order_created_at_gteq],
          params[:order_created_at_lteq],
          false
        )

        options = {
          user_id: current_admin_user.id,
          email: current_admin_user.email,
          params: params,
          store_id: current_store_id,
          order_by: order_by
        }

        options = encrypt_params(options)

        ExportSalesPlanJob.perform_later(options)

        present({ message: "导出任务后台执行，请稍后查看邮箱。" })
      end

      desc "导出到货通知统计"
      params do
        optional :item_title_or_item_sub_title_cont
        optional :barcode_or_no_cont
        optional :item_category_id_eq, type: Integer
        optional :item_minor_category_id_eq, type: Integer
        optional :notice_created_at_gteq, type: DateTime
        optional :notice_created_at_lteq, type: DateTime
      end
      get "sku_in_stock_notice_export" do
        raise CanCan::AccessDenied unless current_user.permissions.include?("sku_in_stock_notices")
        response_error("您还没有设置邮箱。") if current_admin_user.email.blank?

        check_export_list_count

        params["pending_in_stock_notices_count_gteq"] = 1
        params["item_parent_category_id_in"] = current_user.can_read_category_ids

        options = {
          user_id: current_admin_user.id,
          email: current_admin_user.email,
          store_id: current_store_id,
          params: params
        }

        options = encrypt_params(options)

        ExportSkuInStockNoticeJob.perform_later(options)

        present({ message: "导出任务后台执行，请稍后查看邮箱。" })
      end
    end
  end
end
