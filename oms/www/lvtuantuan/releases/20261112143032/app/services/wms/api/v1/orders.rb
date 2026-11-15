# frozen_string_literal: true

module Wms
  class API::V1::Orders < ::API
    @@wms_api_logger = ::Logger.new("./log/wms_api.log")

    # 需要保持 orders API endpoint 不变，所以在现有接口上修改
    namespace :orders, desc: "仓储订单 API" do
      helpers do
        def end_of_association_chain
          MagicBean::WarehouseOrder
        end
      end
      desc "待同步订单", {
        success: API::Entities::Order,
        is_array: true
      }
      paginate
      params do
        use :sign_params
        optional :status, as: :sync_status_eq, type: String, values: %w(confirmed synced), desc: "状态，confirmed：管理员已确认待同步；synced: 已同步； 默认 confirmed", default: "confirmed"
        optional :store_id, as: :store_id_eq, type: Integer, desc: "分店id"
      end
      get do
        params[:sync_status_eq] = "confirmed" if params[:sync_status_eq].blank?

        response_collection
      end

      desc "更新配送时间", {
        success: API::Entities::Order,
        array: true
      }
      params do
        use :sign_params
        requires :orders, type: Array do
          requires :no, type: String, desc: "仓储订单no"
          optional :delivery_date, type: Date, desc: "配送日期"
          optional :delivery_time, type: String, desc: "配送时间段"
          optional :delivery_track, type: String, desc: "ETA URL"
          optional :ata, type: String, desc: "WMS实际送达时间（传过来的时间为悉尼时区，如果使用datetime类型会被专为0时区，所以改为string）"
        end
      end
      post "batch_update_delivery_time" do
        sales_orders, errors = [], []

        ActiveRecord::Base.transaction do
          params[:orders].each do |order_params|
            resource = MagicBean::WarehouseOrder.find_by(no: order_params["no"])
            next unless resource
            warehouse_order_update_params = {
              delivery_date: order_params[:delivery_date].presence || resource.delivery_date,
              prefer_time: order_params[:delivery_time].presence || resource.prefer_time,
            }
            warehouse_order_update_params.merge!(delivery_track: order_params[:delivery_track]) if order_params[:delivery_track].present?

            order_update_params = if order_params[:ata].present?
              warehouse_order_update_params.merge(ata: order_params[:ata]&.in_time_zone)
            else
              warehouse_order_update_params
            end

            begin
              resource.update!(warehouse_order_update_params)
              resource.child_orders.update_all(order_update_params)

              sales_orders.push(*resource.orders) unless resource.shopline?
            rescue ActiveRecord::RecordInvalid => e
              errors << "warehouse order: #{e.record.no}: #{e.message}"
            end
          end
        end

        if errors.any?
          error_message = errors.join(";")
          @@wms_api_logger.info("Error: #{error_message}")
          response_error error_message
        else
          sales_orders.map(&:send_delivery_datetime_sms_and_notification)
          response_success
        end
      end

      desc "更新订单状态", {
        success: API::Entities::Order,
        array: true,
        detail: "订单状态 'order_status' 为 'wait_buyer_confirm_goods' 时发货成功, 订单同步状态'sync_status' 为 'synced' 时已被同步"
      }
      params do
        use :sign_params
        requires :orders, type: Array do
          requires :no, type: String, desc: "订单no"
          requires :status, type: String, values: ["synced", "dispatched", "stockout"], desc: "订单状态"
          requires :courier, type: String, values: ["express", "self_pick", "merchant_delivery"], desc: "配送方式"
          requires :synced_at, type: String, desc: "同步时间（传过来的时间为悉尼时区，如果使用datetime类型会被专为0时区，所以改为string）"
          optional :eta, type: String, desc: "WMS预计送达时间（传过来的时间为悉尼时区，如果使用datetime类型会被专为0时区，所以改为string）"
          optional :tracking_no, type: String, desc: "物流单号"
          optional :delivery_path, type: String, desc: "配送线路"
          optional :stockout_items, type: Array, desc: "stockout_items 数组中的商品为缺货商品" do
            optional :product_id, type: Integer, desc: "sku id"
            optional :sku, type: String, desc: "商品 sku"
            optional :barcode, type: String, desc: "商品 barcode"
            requires :qty, type: Integer, desc: "商品缺货数量，始终为正数"
            at_least_one_of :sku, :barcode
          end
        end
      end
      post "batch" do
        orders, errors = [], []
        params[:orders].each do |order_params|
          resource = MagicBean::WarehouseOrder.find_by(no: order_params["no"])
          next unless resource

          # 更新订单状态
          if order_params["status"].eql?("synced")
            resource.sync_sale_orders!
          elsif order_params["status"].eql?("dispatched")
            stockout_items = order_params.dig(:stockout_items).to_a

            # 为订单创建部分商品售后申请，有货的商品继续走发货流程
            resource.deliver_and_generate_logistic(order_params["tracking_no"], stockout_items, order_params[:eta]&.in_time_zone, order_params["delivery_path"])
          elsif order_params["status"].eql?("stockout")
            # 全部缺货, 则触发退款申请
            resource.sellout_sale_orders!
          end

          if resource.errors.any?
            errors << {
              no: resource.no,
              message: resource.errors.full_messages.join(",")
            }
          else
            resource.update_synced_at_and_eta(order_params[:synced_at]&.in_time_zone, order_params[:eta]&.in_time_zone, order_params[:delivery_path])
            orders << resource
          end
        end
        errors.compact!
        if errors.any?
          @@wms_api_logger.info "Error: #{errors}"
          error!({ errors: errors }, 400)
        else
          present orders, with: API::Entities::Order
        end
      end
    end
  end
end
