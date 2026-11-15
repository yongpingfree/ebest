# frozen_string_literal: true

module BeansAdmin
  class API::V1::VirtualOrders < ::API
    namespace :virtual_orders, desc: "虚拟商品订单接口" do
      helpers ::BeansAdmin::Helpers::OrderChannelPermissionHelper
      helpers do
        def default_order
          "orders.created_at desc"
        end

        def permitted_params
          [:buyer_message, :remark]
        end

        def end_of_association_chain
          channel_permission_values = calculate_order_channel_permissions(current_admin_user)
          @end_of_association_chain ||=
            if params[:item_id].present?
              resource_class.where(
                id: MagicBean::OrderItem.where(item_id: params[:item_id]).pluck(:order_id).uniq,
                channel: channel_permission_values
              )
            else
              resource_class.where(channel: channel_permission_values)
            end
        end

        def collection_search_sentence
          sku_barcode = params[:sku_barcode]&.strip
          chain = if sku_barcode.present?
                    sku = MagicBean::StockKeepingUnit.where(no: sku_barcode, store_id: current_store_id).or(MagicBean::StockKeepingUnit.where(barcode: sku_barcode, store_id: current_store_id)).first
                    end_of_association_chain.where(id: MagicBean::OrderItem.where(stock_keeping_unit_id: sku&.id).select(:order_id))
                  else
                    end_of_association_chain
                  end

          if current_user.can_read_category_ids.present?
            parent_category_id_in = current_user.can_read_category_ids
            items = MagicBean::Item.ransack({ parent_category_id_in: parent_category_id_in }).result
            chain = MagicBean::VirtualOrder.where(id: MagicBean::OrderItem.where(item_id: items.select(:id)).select(:order_id))
          end
        
          if params["category_ids"].present?
            parent_category_id_eq, category_id_eq = params["category_ids"]
            skus = MagicBean::StockKeepingUnit.ransack({ item_parent_category_id_eq: parent_category_id_eq, item_category_id_eq: category_id_eq }).result
            chain = end_of_association_chain.where(id: MagicBean::OrderItem.where(stock_keeping_unit_id: skus.select(:id)).select(:order_id))
          end

          if params["minor_category_ids"].present?
            minor_category_parent_id_eq, minor_category_id_eq = params["minor_category_ids"]
            skus = MagicBean::StockKeepingUnit.ransack({ item_minor_category_parent_id_eq: minor_category_parent_id_eq, item_minor_category_id_eq: minor_category_id_eq }).result
            chain = end_of_association_chain.where(id: MagicBean::OrderItem.where(stock_keeping_unit_id: skus.select(:id)).select(:order_id))
          end

          if params[:only_show_directly_refund_orders].to_s == "true"
            chain = chain.where(id: MagicBean::Payment.refund_payment_type.completed.where(paymentable_type: "MagicBean::Order").select("payments.paymentable_id"))
          end

          if params[:refund_sku_id].present?
            chain = chain.where(id: MagicBean::StockKeepingUnit.find(params[:refund_sku_id]).after_sales.where("after_sales.status IN (1,2,3,5,6)").select(:order_id))
          end

          @collection = chain.accessible_by(current_ability).includes(includes).ransack(ransack_params)
        end

        def includes
          [:store, [coupon: [coupon_template: [:translations]]], :order_items, :user]
        end
      end

      desc "获取订单数"
      params do
        optional :status_eq, values: -> { ::MagicBean::Order.statuses.keys }
        optional :created_at_gteq, type: DateTime
        optional :created_at_lteq, type: DateTime
      end
      get :orders_count do
        orders_count = collection_search_sentence.result.size
        present :orders_count, orders_count
      end

      desc "订单列表", {
        success: API::Entities::VirtualOrder,
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
        MagicBean::Order.where(id: params[:order_ids]).each do |order|
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
