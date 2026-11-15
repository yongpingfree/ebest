# frozen_string_literal: true

module BeansAdmin
  class API::V1::AuctionOrders < ::API
    namespace :auction_orders, desc: "拍卖商品订单接口" do
      helpers do
        def default_order
          "orders.created_at desc"
        end

        def permitted_params
          [:buyer_message, :remark]
        end

        def includes
          [:store, [coupon: [:coupon_template, :user]], :order_items, :user]
        end
      end

      desc "订单列表", {
        success: API::Entities::SimpleOrder,
        is_array: true
      }
      paginate
      params do
        optional :created_at_gteq, type: DateTime
        optional :created_at_lteq, type: DateTime
      end
      get do
        payment_channels = {}
        MagicBean::Payment.charge_payment_type.completed.where(paymentable_type: "MagicBean::Order", paymentable_id: paginate(collection).ids).each { |payment| payment_channels[payment.paymentable_id] = payment.channel }

        authorize_and_response_collection(params: { payment_channels: payment_channels })
      end

      desc "导出订单列表"
      params do
        optional :created_at_gteq, type: DateTime
        optional :created_at_lteq, type: DateTime
      end
      get "export" do
        response_error("您还没有设置邮箱。") if current_admin_user.email.blank?

        check_export_list_count

        validate_export_datetime_params(
          params[:created_at_gteq],
          params[:created_at_lteq]
        )

        if params[:created_at_gteq].blank?
          params[:created_at_gteq] = (Date.current - 31.days).beginning_of_day
          params[:created_at_lteq] = Time.current
        end

        redis_key = "orders_export_ids_#{Time.current.to_i}"
        Rails.cache.write(redis_key, collection.map(&:id), expires_in: 100.minutes)

        options =  {
          email: current_admin_user.email,
          redis_key: redis_key,
          order_by: params[:order_by] || default_order,
          sku_id: params[:order_items_stock_keeping_unit_id_eq]
        }

        options = encrypt_params(options)

        ExportOrderJob.perform_later(options)
        present({ message: "导出任务后台执行，请稍后查看邮箱。" })
      end

      desc "批量确认订单", {
        success: API::Entities::SuccessfulResult
      }
      params do
        requires :order_ids, type: Array[Integer], coerce_with: ->(val) { val.split(/[,]/).map(&:strip).map(&:to_i) }
      end
      put "batch_finish" do
        response_error "请选择可确认的订单" if params[:order_ids].blank?
        MagicBean::AuctionOrder.where(id: params[:order_ids]).each do |order|
          order.finish! if order.wait_seller_send_goods?
        end
        response_success
      end

      route_param :id do
        desc "订单详情", {
          success: API::Entities::Order
        }
        get do
          authorize_and_response_resource
        end

        desc "编辑订单", {
          success: API::Entities::Order
        }
        params do
          optional :buyer_message, type: String, desc: "订单备注"
          optional :remark, type: String, desc: "订单备注"
          optional :receiver_first_name, type: String, desc: "联系人名"
          optional :receiver_last_name, type: String, desc: "联系人姓"
          optional :receiver_tel_number, type: String, desc: "联系人手机号"
          optional :receiver_email, type: String, desc: "联系人email"
        end
        put do
          resource.receiver_properties.merge!(
            {
              tel_number: params[:receiver_tel_number].presence,
              first_name: params[:receiver_first_name].presence,
              last_name: params[:receiver_last_name].presence,
              email: params[:receiver_email].presence,
            }.as_json)

          authorize_and_update_resource
        end

        before do
          action_name = request.path.split("/").last
          @log_message = I18n.t("attributes.order.#{action_name}")
        end

        desc "同意直接退款", {
          success: API::Entities::VirtualOrder
        }
        put "agree_refund" do
          authorize_and_run_member_action(:agree_refund, { method: :perform_aasm_event, log_message: @log_message }, :refund)
        end

        desc "拒绝直接退款", {
          success: API::Entities::VirtualOrder
        }
        put "refuse_refund" do
          authorize_and_run_member_action(:refuse_refund, { method: :perform_aasm_event, log_message: @log_message }, :refuse)
        end

        desc "直接退款", {
          success: API::Entities::VirtualOrder
        }
        put "direct_refund" do
          authorize_and_run_member_action(:direct_refund, { method: :perform_aasm_event, log_message: @log_message }, :refund)
        end
        desc "完成订单", {
          success: API::Entities::VirtualOrder
        }
        put "finish" do
          authorize_and_run_member_action(:finish_order, { method: :finish!, log_message: @log_message })
        end

        desc "重新打开售后", {
          success: API::Entities::VirtualOrder
        }
        put "reopen_after_sale" do
          authorize_and_run_member_action(:reopen_after_sale, {})
        end

        desc "订单发货发货", {
          success: API::Entities::SuccessfulResult
        }
        params do
          requires :company, type: String, desc: "快递公司"
          requires :no, type: String, desc: "快递单号"
        end
        post "virtual_deliver" do
          authorize! :virtual_deliver, resource
          resource.deliver_and_generate_logistic(params[:no], company: params[:company])
          response_success
        end
      end
    end
  end
end
