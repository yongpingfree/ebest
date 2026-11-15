# frozen_string_literal: true
module BeansAdmin
  class API::V1::OperationRecords < ::API

    namespace :operation_records, desc: "管理员操作记录 API" do
      helpers do
        def includes
          [:operatable, admin_user: [:admin_user_stores, :stores]]
        end
      end
      desc "管理员操作记录 列表", {
        success: API::Entities::OperationRecord,
        is_array: true
      }
      paginate
      params do
        optional :order_no_or_after_sale_refund_no, type: String, desc: "订单号/售后单号"
        optional :item_title, type: String, desc: "产品操作对象名称"
      end
      get do
        if params[:order_no_or_after_sale_refund_no].present?
          @collection = collection.where(operatable_type: "MagicBean::Order", operatable_id: MagicBean::Order.ransack({ no_cont: params[:order_no_or_after_sale_refund_no] }).result.select(:id))
                          .or(collection.where(operatable_type: "MagicBean::AfterSale", operatable_id: MagicBean::AfterSale.ransack({ refund_no_cont: params[:order_no_or_after_sale_refund_no] }).result.select(:id)))
        elsif params[:item_title].present?
          @collection = collection.where(operatable_type: "MagicBean::Item", operatable_id: MagicBean::Item.ransack({ translated_searchable_title_cont: params[:item_title] }).result.select(:id))
        end

        authorize_and_response_collection
      end

      desc "导出"
      get "export" do
        response_error("您还没有设置邮箱。") if current_admin_user.email.blank?

        check_export_list_count

        options = {
          user_id: current_admin_user.id,
          email: current_admin_user.email,
          store_id: current_store_id,
          params: params
        }

        options = encrypt_params(options)

        ExportOperationRecordJob.perform_later(options)

        present({ message: "导出任务后台执行，请稍后查看邮箱。" })
      end

      route_param :id do
        desc "管理员操作记录 详情", {
          success: API::Entities::OperationRecord
        }
        get do
          authorize_and_response_resource
        end
      end
    end
  end
end
