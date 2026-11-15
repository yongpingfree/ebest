# frozen_string_literal: true

module BeansAdmin
  class API::V1::Orders < ::API

    namespace :orders, desc: "订单接口" do
      helpers ::BeansAdmin::Helpers::OrderChannelPermissionHelper
      helpers do
        def default_order
          "orders.id desc"
        end

        def permitted_params
          [:buyer_message, :remark, :freight_remark, :delivery_date, :prefer_time, :authority_to_leave, :deliver_to_door, :delivery_time_period_setting_id]
        end

        def resource_type
          @resource_type ||= params.delete(:resource_type)
        end

        def resource_class
          return @resource_class if @resource_class
          @resource_class = MagicBean::Order if resource_type.blank?
          @resource_class ||= (resource_type == "groupon_orders" ? MagicBean::GrouponOrder : MagicBean::Order)
        end

        def end_of_association_chain
          channel_permission_values = calculate_order_channel_permissions(current_admin_user)
          order_basic_collection = if resource_type == "groupon_orders"
                                     MagicBean::GrouponOrder.where(channel: channel_permission_values)
                                   else
                                     types = ["MagicBean::NormalOrder"]
                                     types << "MagicBean::SameDayDeliveryOrder" unless resource_type == "ae_orders"
                                     types << "MagicBean::VirtualOrder" if params[:include_virtual_orders]
                                     MagicBean::Order.where(
                                      type: types,
                                      channel: channel_permission_values
                                    )
                                   end
          @end_of_association_chain ||=
            if params[:item_id].present?
              order_basic_collection.where(id: MagicBean::OrderItem.where(item_id: params[:item_id]).select(:order_id))
            else
              order_basic_collection
            end

          if params[:gift_coupon_template_id].present?
            @end_of_association_chain = @end_of_association_chain.where(gift_coupon_template_id: params[:gift_coupon_template_id]).or(@end_of_association_chain.where("pool_coupon_template_ids @> ARRAY[?]::integer[]", [params[:gift_coupon_template_id]]))
          end

          @end_of_association_chain
        end

        def collection_search_sentence
          sku_barcode = params[:sku_barcode]&.strip

          chain = end_of_association_chain

          if sku_barcode.present?
            sku = MagicBean::StockKeepingUnit.where(no: sku_barcode, store_id: current_store_id).or(MagicBean::StockKeepingUnit.where(barcode: sku_barcode, store_id: current_store_id)).first
            chain = chain.where(id: MagicBean::OrderItem.where(stock_keeping_unit_id: sku&.id).select(:order_id))
          end

          if params[:only_show_same_day_delivery_orders].to_s == "true"
            chain = chain.where(type: "MagicBean::SameDayDeliveryOrder")
          end

          if params[:only_show_directly_refund_orders].to_s == "true"
            chain = chain.where(id: MagicBean::Payment.refund_payment_type.completed.where(paymentable_type: "MagicBean::Order").select("payments.paymentable_id"))
          end

          if params[:refund_sku_id].present?
            chain = chain.where(id: MagicBean::StockKeepingUnit.find(params[:refund_sku_id]).after_sales.where("after_sales.status IN (1,2,3,5,6)").select(:order_id))
          end

          if params[:gift_sku_id].present?
            chain = chain.paid.where.not(gifts_properties: nil).where("EXISTS (SELECT FROM json_array_elements(orders.gifts_properties) gift_element WHERE (gift_element->>'stock_keeping_unit_id')::int = ?)", params[:gift_sku_id])
          end

          if params[:pool_gift_sku_id].present?
            chain = chain.paid.where.not(pool_gifts_properties: nil).where("EXISTS (SELECT FROM json_array_elements(orders.pool_gifts_properties) gift_element WHERE (gift_element->>'stock_keeping_unit_id')::int = ?)", params[:pool_gift_sku_id])
          end

          if params[:order_invoice_state_in].present? && params[:order_invoice_state_in].include?("none")
            not_in_invoice_states = MagicBean::OrderInvoice.states.keys - params.delete(:order_invoice_state_in) + [-1]
            @collection = chain.accessible_by(current_ability).includes(includes).where.not(id: MagicBean::OrderInvoice.ransack(state_in: not_in_invoice_states).result.select(:order_id)).ransack(ransack_params)
          else
            @collection = chain.accessible_by(current_ability).includes(includes).ransack(ransack_params)
          end
        end

        def collection_result_sentence
          order_by = params[:order_by].split(",").map(&:strip).compact if params[:order_by].present?
          @collection =
            if order_by
              @collection.sorts = order_by
              @collection.result
            else
              @collection.result.order(default_order)
            end
        end

        def includes
          @includes = [:logistics, :order_invoice, [coupon: [coupon_template: [:translations]]], [order_items: :item], :user, :store, :warehouse_order]
          @includes = @includes + [:groupon] if resource_type.eql?("groupon_orders")
          @includes
        end
      end

      desc "获取订单数"
      params do
        optional :status_eq, values: -> { ::MagicBean::Order.statuses.keys }
        optional :created_at_gteq_datetime, type: DateTime
        optional :created_at_lteq_datetime, type: DateTime
        optional :delivery_type_eq, values: -> { ::MagicBean::Order.delivery_types.keys }
        optional :delivery_date_gteq, type: Date
        optional :delivery_date_lteq, type: Date
        optional :include_virtual_orders, type: Boolean, default: false
        optional :ae_drop_shipper_eq, type: Boolean, default: false
      end
      get :orders_count do
        orders_count = collection_search_sentence.result.size
        present :orders_count, orders_count
      end

      desc "订单列表", {
        success: API::Entities::SimpleOrder,
        is_array: true
      }
      paginate
      params do
        optional :created_at_gteq, type: DateTime
        optional :created_at_lteq, type: DateTime
        optional :delivery_type_eq, values: -> { ::MagicBean::Order.delivery_types.keys }
        optional :delivery_date_gteq, type: Date
        optional :delivery_date_lteq, type: Date
        optional :ae_drop_shipper_eq, type: Boolean, default: false
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
        optional :delivery_type_eq, values: -> { ::MagicBean::Order.delivery_types.keys }
        optional :delivery_date_gteq, type: Date
        optional :delivery_date_lteq, type: Date
        optional :ae_drop_shipper_eq, type: Boolean, default: false
      end
      get "export" do
        response_error("您还没有设置邮箱。") if current_admin_user.email.blank?

        check_export_list_count

        validate_export_datetime_params(
          params[:created_at_gteq],
          params[:created_at_lteq]
        )

        validate_export_date_params(
          params[:delivery_date_gteq],
          params[:delivery_date_lteq]
        )

        if params[:created_at_gteq].blank? && params[:delivery_date_gteq].nil?
          params[:created_at_gteq] = (Date.current - 31.days).beginning_of_day
          params[:created_at_lteq] = Time.current
        end

        redis_key = "orders_export_ids_#{Time.current.to_i}"
        Rails.cache.write(redis_key, collection.pluck(:id), expires_in: 100.minutes)

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

      desc "导入物流回传单", {
        detail: <<-NOTES.strip_heredoc
        ```json
          {
            errors: [
              {
                order_no: '',
                no: '',
                company: '',
                remark: '',
                message: ''
              }
            ]
          }
        ```
        NOTES
      }
      params do
        requires :file, type: File, desc: "xlsx 文件"
      end
      post :import_logistics do
        begin
          error_count = 0
          package = Axlsx::Package.new do |p|
            xlsx = Roo::Spreadsheet.open params[:file]["tempfile"].path
            result = xlsx.parse order_no: "订单号", no: "物流单号", company: "物流公司", remark: "备注"

            p.workbook.add_worksheet do |sheet|
              sheet.add_row %w(订单号 物流单号 物流公司 备注 错误信息)

              result.each do |item|
                resource = MagicBean::Order.find_by no: item[:order_no].to_s.gsub(/\W+/, "")
                row = [item[:order_no].to_s, item[:no].to_s, item[:company], item[:remark]]

                if resource.nil?
                  row.push "订单不存在"
                  sheet.add_row row, types: [:string]
                  error_count += 1
                else
                  logistic = resource.logistics.new item.except(:order_no)
                  unless logistic.save
                    row.push logistic.errors.full_messages.join("，")
                    sheet.add_row row, types: [:string]
                    error_count += 1
                  end
                end
              end
            end
          end

          header["x-error-count"] = error_count
          content_type "application/octet-stream"
          env["api.format"] = :binary

          present package.to_stream.read
        rescue Roo::Error => e
          response_error e.message
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
        response_error "选择的订单中存在跨境购订单，不能确认" if MagicBean::Order.where(id: params[:order_ids], ae_drop_shipper: true).exists?

        confirm_nos = []
        MagicBean::Order.where(id: params[:order_ids]).each do |order|
          if order.pending?
            order.confirmed!
            confirm_nos << order.no
          end
        end

        if confirm_nos.present?
          log_message = "批量确认订单，订单号: #{confirm_nos.join("，")}"
          current_admin_user.operation_records.create(content: log_message, store_id: current_store_id)
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
          optional :freight_remark, type: String, desc: "运费备注"
          optional :receiver_first_name, type: String, desc: "收货人名"
          optional :receiver_last_name, type: String, desc: "收货人姓"
          optional :receiver_tel_number, type: String, desc: "收货人手机号"
          optional :receiver_unit_number, type: String, desc: "收件人单元号"
          optional :receiver_street_number, type: String, desc: "收件人街道号"
          optional :receiver_street, type: String, desc: "收件人街道地址"
          optional :receiver_city_name, type: String, desc: "收件人Suburb"
          optional :receiver_province_name, type: String, desc: "收件人州"
          optional :receiver_postal_code, type: String, desc: "收件人邮编"
          optional :authority_to_leave, type: Boolean, desc: "是否放在门口"
        end
        put do
          response_error("手机号 #{params[:receiver_tel_number]} 已被拉黑，请重新输入") if params[:receiver_tel_number].present? && MagicBean::MobileBlacklist.activated?(params[:receiver_tel_number].strip, :order_disabled)

          log_messages = []
          new_pure_detail_info = "#{params[:receiver_street_number]} #{params[:receiver_street]}".strip.presence
          new_unit_number = params[:receiver_unit_number].presence
          detail_info = new_unit_number.present? ? "#{ new_unit_number }/#{new_pure_detail_info}" : new_pure_detail_info
          old_receiver_properties = resource.human_receiver_properties

          if new_pure_detail_info.present?
            resource.receiver_properties.merge!(
              {
                province_name: params[:receiver_province_name].presence,
                city_name: params[:receiver_city_name].presence,
                pure_detail_info: new_pure_detail_info,
                detail_info: detail_info,
                tel_number: params[:receiver_tel_number].presence,
                first_name: params[:receiver_first_name].presence,
                last_name: params[:receiver_last_name].presence,
                postal_code: params[:receiver_postal_code].presence,
                street_number: params[:receiver_street_number].presence,
                street: params[:receiver_street].presence,
                unit_number: new_unit_number
              }.as_json)
          end

          log_messages << "将收货信息从 #{old_receiver_properties || "空"} 改为 #{resource.human_receiver_properties || "空"}" if old_receiver_properties.to_s != resource.human_receiver_properties.to_s
          log_messages << "将买家留言从 #{resource.buyer_message.presence || "空"} 改为 #{params[:buyer_message].presence || "空"}" if params[:buyer_message].presence.to_s != resource.buyer_message.presence.to_s
          log_messages << "将订单备注从 #{resource.remark.presence || "空"} 改为 #{params[:remark].presence || "空"}" if params[:remark].presence.to_s != resource.remark.presence.to_s
          log_messages << "将运费备注从 #{resource.freight_remark.presence || "空"} 改为 #{params[:freight_remark].presence || "空"}" if params[:freight_remark].presence.to_s != resource.freight_remark.presence.to_s

          authorize_and_update_resource({ log_message: log_messages.join(", ") })
        end

        desc "编辑订单配送时间", {
          success: API::Entities::Order
        }
        params do
          optional :delivery_time_period_setting_id, type: Integer, desc: "配送时间段id"
          optional :delivery_date, type: String, desc: "预计发货日期"
          optional :prefer_time, type: String, desc: "预计发货时间"
          optional :sync_child_orders, type: Boolean, desc: "是否同步更新子订单"
        end
        put "delivery_message" do
          if params[:delivery_time_period_setting_id].present?
            period_setting = MagicBean::DeliveryTimePeriodSetting.find_by(id: params[:delivery_time_period_setting_id])
            response_error("配送时间段不存在") if period_setting.blank?

            params[:prefer_time] = period_setting.prefer_time
          end

          log_messages = []
          log_messages << "将发货日期#{resource.delivery_date}改为#{params[:delivery_date]}" if params[:delivery_date].present? && resource.delivery_date != params[:delivery_date]
          log_messages << "将发货时间#{resource.prefer_time}改为#{params[:prefer_time]}" if params[:prefer_time].present? && resource.prefer_time != params[:prefer_time]

          # 前端会传prefer_time过来，但值为空，导致订单的prefer_time被清空
          params.delete(:prefer_time) if params[:prefer_time].nil?
          params.delete(:delivery_time_period_setting_id) if params[:delivery_time_period_setting_id].nil?

          authorize! :update, resource

          # sync_child_orders为true, 且order为母单，并没有其他母单
          update_child_orders = params[:sync_child_orders] && resource.status.in?(["risk_pay", "wait_seller_send_goods"]) && !resource.is_child && !resource.has_other_parent_orders?

          child_orders = resource.child_orders if update_child_orders

          if resource.update(resource_params)
            current_admin_user.operation_records.create(operatable: resource, content: log_messages.join(", "), store_id: current_store_id) if log_messages.present?
            
            if update_child_orders
              child_orders.each do |child_order|
                child_order.update(resource_params)
              end
            end
            
            response_resource
          else
            response_record_error(resource)
          end
        end

        desc "测试发货", {
          success: API::Entities::SuccessfulResult
        }
        post "fake_deliver" do
          authorize! :deliver, resource

          resource.deliver_and_generate_logistic("", fake: true)
          response_success
        end

        before do
          action_name = request.path.split("/").last
          @log_message = I18n.t("attributes.order.#{action_name}")
        end

        desc "待收货订单退款", {
          success: API::Entities::Order
        }
        params do
          requires :refund_amount_in_yuan, type: Float, desc: "退款金额($)"
        end
        put "deliver_order_refund" do
          # 只有待收货且没有有效售后的订单才能退款
          response_error(I18n.t("error.order.deliver_order_cannot_be_refunded")) unless resource.wait_buyer_confirm_goods? && resource.after_sales.effective.empty?
          response_error(I18n.t("error.order.refund_amount_should_be_larger_than_zero")) if params[:refund_amount_in_yuan].zero?
          response_error(I18n.t("error.order.ae_order_cannot_be_refunded")) if resource.ae_drop_shipper
          response_error(I18n.t("error.order.deliver_order_cannot_be_refunded")) unless resource.may_refund?
          # 子弹不能单独退款
          response_error(I18n.t("error.order.cannot_refund_child_order_after_delivery")) if resource.is_child
          
          authorize_and_run_member_action(:refund, { method: :deliver_order_refund, log_message: @log_message }, params)
        end

        desc "同意直接退款", {
          success: API::Entities::Order
        }
        put "agree_refund" do
          authorize_and_run_member_action(:agree_refund, { method: :perform_aasm_event, log_message: @log_message }, :refund)
        end

        desc "拒绝直接退款", {
          success: API::Entities::Order
        }
        put "refuse_refund" do
          authorize_and_run_member_action(:refuse_refund, { method: :perform_aasm_event, log_message: @log_message }, :refuse)
        end

        desc "直接退款", {
          success: API::Entities::Order
        }
        put "direct_refund" do
          authorize_and_run_member_action(:direct_refund, { method: :perform_aasm_event, log_message: @log_message }, :refund)
        end

        desc "确认订单", {
          success: API::Entities::Order
        }
        put "confirm" do
          response_error "跨境购订单不能确认订单" if resource.ae_drop_shipper
          authorize_and_run_member_action(:confirm_order, { method: :confirmed!, log_message: @log_message })
        end

        desc "重新打开售后", {
          success: API::Entities::Order
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

        desc "完成订单", {
          success: API::Entities::Order
        }
        put "finish" do
          authorize_and_run_member_action(:finish_order, { method: :finish!, log_message: @log_message })
        end

        desc "手动生成仓储订单", {
          success: API::Entities::Order
        }
        post "warehouse_orders" do
          authorize! :update, resource

          # can_create_warehouse_order方法会把warehouse_order_id存在的过滤掉          
          if resource.can_create_warehouse_order?
            # 检查修改配送日期是否在隔天，且当前时间是否超过截单时间，如果符合条件，则自动生成独立仓储订单
            independent = false
            # TODO: 如果截单时间是23:59, 这里会无法生成独立仓储订单，但目前悉尼门店不会这样设置，且这种情况发生的概率很小，所以暂时不处理
            independent = true if resource.delivery_date.to_date == Date.current.tomorrow && Time.current.strftime("%H:%M") >= resource.send(:current_store_cutoff_time_string)

            resource.generate_warehouse_order(independent)
            response_resource
          else
            response_error(I18n.t("error.order.wrong_status_to_create_warehouse_order"))
          end
        end
      end
    end
  end
end
