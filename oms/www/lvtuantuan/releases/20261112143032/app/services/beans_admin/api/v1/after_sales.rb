# frozen_string_literal: true

module BeansAdmin
  class API::V1::AfterSales < ::API

    namespace :after_sales, desc: "售后列表" do
      helpers do
        def includes
          [:user, :order, :lastest_operator, after_sales_order_items: [:order_item]]
        end

        def permitted_params
          [:order_id, :user_id, :reason, :after_sale_type, :amount_in_cent, :amount_in_yuan, :store_id, :applicant_type, :return_type, :internal_reason, :department, :is_real_claim, :audit_explain, :audit_video, audit_images: [], after_sales_order_items_attributes: [:id, :quantity, :order_item_id, :service_amount_in_yuan, :cost_integral, :gift_card_amount_in_yuan, :cash_amount_in_yuan, :ae_gst_amount_in_yuan]]
        end
      end

      desc "售后列表", {
        success: API::Entities::SimpleAfterSale,
        is_array: true
      }
      paginate
      params do
        use :created_at_search
        optional :status_eq, type: String, values: ->() { MagicBean::AfterSale.statuses.keys }, desc: "状态搜索"
        optional :after_sale_type_eq, type: String, values: ->() { MagicBean::AfterSale.after_sale_types.keys }, desc: "售后类型搜索"
        optional :return_type_eq, type: String, values: ->() { MagicBean::AfterSale.return_types.keys }, desc: "退款类型搜索"
        optional :refund_no_cont, type: String, desc: "售后单号搜索"
        optional :order_no_cont, type: String, desc: "订单号搜索"
        optional :user_nickname_cont, type: String, desc: "用户昵称搜索"
        optional :user_mobile_cont, type: String,  desc: "用户手机搜索"
      end
      get do
        authorize_and_response_collection
      end

      desc "导出售后列表"
      params do
        use :created_at_search
        optional :status_eq, type: String, values: ->() { MagicBean::AfterSale.statuses.keys }, desc: "状态搜索"
        optional :after_sale_type_eq, type: String, values: ->() { MagicBean::AfterSale.after_sale_types.keys }, desc: "售后类型搜索"
        optional :return_type_eq, type: String, values: ->() { MagicBean::AfterSale.return_types.keys }, desc: "退款类型搜索"
        optional :refund_no_cont, type: String, desc: "售后单号搜索"
        optional :order_no_cont, type: String, desc: "订单号搜索"
        optional :user_nickname_cont, type: String, desc: "用户昵称搜索"
        optional :user_mobile_cont, type: String,  desc: "用户手机搜索"
      end
      get "export" do
        response_error("您还没有设置邮箱。") if current_admin_user.email.blank?

        check_export_list_count

        redis_key = "after_sales_export_ids_#{Time.current.to_i}"
        Rails.cache.write(redis_key, collection.pluck(:id), expires_in: 100.minutes)

        options =  {
          email: current_admin_user.email,
          redis_key: redis_key,
          order_by: params[:order_by] || default_order
        }

        options = encrypt_params(options)

        ExportAfterSalesJob.perform_later(options)
        present({ message: "导出任务后台执行，请稍后查看邮箱。" })
      end

      desc "批量修改内部原因", {
        success: API::Entities::SuccessfulResult
      }
      params do
        requires :after_sale_ids, type: Array[Integer], coerce_with: ->(val) { val.split(/[,]/).map(&:strip).map(&:to_i) }
        optional :is_real_claim, type: Boolean, desc: "是否真实理赔"
        optional :internal_reason, type: String, desc: "内部原因"
        optional :department, type: String, desc: "责任部门"
        optional :audit_explain, type: String, desc: "审核说明"
        optional :audit_images, type: Array[String], desc: "审核说明"
        optional :audit_video, type: String, desc: "审核视频"
        at_least_one_of :internal_reason, :department, :audit_explain, :audit_images, :audit_video
      end
      put "batch_reset_refund_messages" do
        response_error "请选择要修改的售后" if params[:after_sale_ids].blank?
        after_sales = MagicBean::AfterSale.where(id: params.delete(:after_sale_ids))
        params[:is_real_claim] = false if params[:is_real_claim].nil?

        error_messages = []
        begin
          MagicBean::AfterSale.transaction do
            after_sales.each do |after_sale|
              error_messages << "售后单号#{after_sale.refund_no} #{after_sale.errors.full_messages.join(", ")}" unless after_sale.update(declared(params, include_missing: false))
            end

            raise ActiveRecord::RecordInvalid if error_messages.present?
          end

          if after_sales.present?
            log_message = "批量修改内部原因，售后单号为：#{after_sales.map(&:refund_no).join("; ")}, 内部原因：#{params[:internal_reason]}, 责任部门： #{params[:department]}, 是否真实理赔：#{params[:is_real_claim]}, 审核说明：#{params[:audit_explain]}, 审核图片：#{params[:audit_images]}, 审核视频：#{params[:audit_video]}"
            current_admin_user.operation_records.create(content: log_message, store_id: current_store_id)
          end

          response_success
        rescue => _
          response_error(error_messages.join("; "))
        end
      end

      desc "新增售后", {
        success: API::Entities::AfterSale
      }
      params do
        requires :order_id, type: Integer
        requires :reason, type: String
        requires :after_sale_type, type: String
        optional :images, type: Array[String]
        requires :after_sales_order_items_attributes, type: Array do
          requires :quantity, type: Integer
          requires :order_item_id, type: Integer
        end
      end
      post do
        order = MagicBean::Order.find(params[:order_id])
        params["user_id"] = order.user_id
        params["store_id"] = order.store_id
        params["applicant_type"] = "admin"
        authorize_and_create_resource
      end

      route_param :id do
        desc "售后详情", { success: API::Entities::AfterSale }
        get do
          authorize_and_response_resource
        end

        desc "更新售后", { success: API::Entities::AfterSale }
        params do
          requires :amount_in_yuan, type: Float, desc: "退款金额"
        end
        put do
          log_message = "更新实退金额为：#{params[:amount_in_yuan]}"
          authorize_and_update_resource(log_message: log_message)
        end

        desc "更新售后订单项金额", { success: API::Entities::AfterSale }
        params do
          requires :after_sales_order_items_attributes, type: Array do
            requires :id, type: Integer
            requires :service_amount_in_yuan, type: Float, desc: "退款手续费"
            requires :cost_integral, type: Integer, desc: "退款金币"
            requires :gift_card_amount_in_yuan, type: Float, desc: "退款礼品卡"
            requires :cash_amount_in_yuan, type: Float, desc: "退款现金"
            requires :ae_gst_amount_in_yuan, type: Float, desc: "退款GST金额"
          end
        end
        put "reset_refund_amount" do
          params[:store_id] = resource.store_id
          response_error("只有等待卖家同意的售后可以修改金额") unless resource.wait_seller_agree?
          log_messages = []
          item = params[:after_sales_order_items_attributes].first
          original_item = resource.after_sales_order_items.find(item[:id])
          log_messages << "退款手续费从 $#{original_item.service_amount_in_yuan} 改为 $#{item[:service_amount_in_yuan]}" if item[:service_amount_in_yuan] != original_item.service_amount_in_yuan.to_f
          log_messages << "退款金币从 #{original_item.cost_integral} 改为 #{item[:cost_integral]}" if item[:cost_integral] != original_item.cost_integral
          log_messages << "退款礼品卡从 $#{original_item.gift_card_amount_in_yuan} 改为 $#{item[:gift_card_amount_in_yuan]}" if item[:gift_card_amount_in_yuan] != original_item.gift_card_amount_in_yuan.to_f
          log_messages << "退款现金从 $#{original_item.cash_amount_in_yuan} 改为 $#{item[:cash_amount_in_yuan]}" if item[:cash_amount_in_yuan] != original_item.cash_amount_in_yuan.to_f
          log_messages << "退款GST金额从 $#{original_item.ae_gst_amount_in_yuan} 改为 $#{item[:ae_gst_amount_in_yuan]}" if item[:ae_gst_amount_in_yuan] != original_item.ae_gst_amount_in_yuan.to_f

          log_message = "订单项编号为 #{item[:id]}，#{log_messages.join("，")}"

          authorize_and_update_resource(log_message: log_message)
        end

        desc "更新售后订单项数量", { success: API::Entities::AfterSale }
        params do
          requires :after_sales_order_items_attributes, type: Array do
            requires :id, type: Integer
            requires :quantity, type: Integer, desc: "数量"
          end
        end
        put "reset_refund_quantity" do
          params[:store_id] = resource.store_id
          response_error("只有等待卖家同意的售后可以修改数量") unless resource.wait_seller_agree?

          log_message = nil
          item = params[:after_sales_order_items_attributes].first
          original_item = resource.after_sales_order_items.find(item[:id])
          log_message = "订单项编号为 #{item[:id]}，数量从 #{original_item.quantity} 改为 #{item[:quantity]}" if item[:quantity] != original_item.quantity

          authorize_and_update_resource(log_message: log_message)
        end

        desc "更新售后信息", { success: API::Entities::AfterSale }
        params do
          requires :is_real_claim, type: Boolean, desc: "是否真实理赔"
          optional :internal_reason, type: String, desc: "内部原因"
          optional :department, type: String, desc: "责任部门"
          optional :audit_explain, type: String, desc: "审核说明"
          optional :audit_images, type: Array[String], desc: "审核说明"
          optional :audit_video, type: String, desc: "审核视频"
          at_least_one_of :internal_reason, :department, :audit_explain, :audit_images, :audit_video
        end
        put "reset_refund_messages" do
          params[:store_id] = resource.store_id
          log_messages = []
          log_messages << "内部原因从 #{resource.internal_reason} 改为 #{params[:internal_reason]}" if params[:internal_reason].present? && params[:internal_reason] != resource.internal_reason
          log_messages << "责任部门从 #{resource.department} 改为 #{params[:department]}" if params[:department].present? && params[:department] != resource.department
          log_messages << "是否真实理赔从 #{resource.is_real_claim} 改为 #{params[:is_real_claim]}" if params[:is_real_claim].present? && params[:is_real_claim] != resource.is_real_claim
          log_messages << "审核说明从 #{resource.audit_explain} 改为 #{params[:audit_explain]}" if params[:audit_explain].present? && params[:audit_explain] != resource.audit_explain
          log_messages << "审核图片从 #{resource.audit_images} 改为 #{params[:audit_images]}" if params[:audit_images].present? && params[:audit_images] != resource.audit_images
          log_messages << "审核视频从 #{resource.audit_video} 改为 #{params[:audit_video]}" if params[:audit_video].present? && params[:audit_video] != resource.audit_video
          authorize_and_update_resource(log_message: log_messages.join("，"))
        end

        before do
          action_name = request.path.split("/").last
          @log_message = I18n.t("attributes.after_sale.#{action_name}")
        end

        desc "同意售后", { success: API::Entities::AfterSale }
        put "agree" do
          response_error("内部原因和责任部门必须都填写才能同意售后") if resource.internal_reason.blank? || resource.department.blank?
          
          begin
            resource.lastest_operator_id = current_admin_user.id
            authorize_and_run_member_action(:agree, { method: :agree!, log_message: @log_message })
          rescue RestClient::Exceptions::ReadTimeout
            response_error("微信退款连接超时，请稍后再试")
          rescue StandardError => e
            response_error e.message
          end
        end

        desc "同意退货退款售后并退款", { success: API::Entities::AfterSale }
        put "agree_and_refund" do
          begin
            resource.update after_sale_type: :refund, lastest_operator_id: current_admin_user.id
            authorize_and_run_member_action(:agree, { method: :agree!, log_message: @log_message })
          rescue RestClient::Exceptions::ReadTimeout
            response_error("微信退款连接超时，请稍后再试")
          rescue StandardError => e
            response_error e.message
          end
        end

        desc "拒绝售后", { success: API::Entities::AfterSale }
        params do
          requires :seller_reply, type: String, desc: "拒绝理由"
        end
        put "refuse" do
          resource.seller_reply = params[:seller_reply]
          resource.lastest_operator_id = current_admin_user.id
          @log_message = "#{@log_message}, 拒绝理由为: #{params[:seller_reply]}"
          begin
            authorize_and_run_member_action(:refuse, { method: :refuse!, log_message: @log_message })
          rescue StandardError => e
            response_error e.message
          end
        end

        desc "确定售后收货", { success: API::Entities::AfterSale }
        put "confirm" do
          begin
            resource.lastest_operator_id = current_admin_user.id
            authorize_and_run_member_action(:confirm, { method: :confirm!, log_message: @log_message })
          rescue RestClient::Exceptions::ReadTimeout
            response_error("微信退款连接超时，请稍后再试")
          rescue StandardError => e
            response_error e.message
          end
        end

        desc "拒绝退款", { success: API::Entities::AfterSale }
        put "reject" do
          begin
            resource.lastest_operator_id = current_admin_user.id
            authorize_and_run_member_action(:reject, { method: :reject!, log_message: @log_message })
          rescue StandardError => e
            response_error e.message
          end
        end
      end
    end
  end
end
