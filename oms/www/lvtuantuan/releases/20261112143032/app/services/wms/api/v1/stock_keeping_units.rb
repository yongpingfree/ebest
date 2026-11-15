# frozen_string_literal: true

module Wms
  class API::V1::StockKeepingUnits < ::API
    # 商品 API

    namespace :stock_keeping_units, desc: "商品 API" do

      helpers do
        def default_order
          ["created_at desc"]
        end

        def calculate_sku_quantity_change(new_quantity, sku)
          error = nil
          log = nil
          sku_info = "SKU #{sku.no}, id: #{sku.id},"
          old_sku_quantity = sku.quantity
          active_promotion_prices = sku.time_limited_promotion_prices.active
          need_to_update_promotion_price_reserved_quantity = false
          promotion_price = nil
          old_promotion_price_reserved_quantity = nil
          new_promotion_price_reserved_quantity = nil

          if active_promotion_prices.size == 0
            # 没有限时优惠时更新 sku 的库存
            sku.quantity = old_sku_quantity + new_quantity
            if sku.quantity.negative?
              error = "#{sku_info} 调拨库存不足，差#{sku.quantity.abs}个"
            else
              log = "#{sku_info} 库存由 #{old_sku_quantity} 改为 #{sku.quantity}"
            end
          elsif active_promotion_prices.size == 1
            # 有限时优惠时更新库存到限时优惠的临时预留库存上
            promotion_price = active_promotion_prices.first
            if new_quantity.positive?
              if promotion_price.time_limited_promotion.save_qty_to_promotion_price?
                sku.quantity = old_sku_quantity + new_quantity
                log = "#{sku_info} 库存由 #{old_sku_quantity} 改为 #{sku.quantity}"
              else
                old_promotion_price_reserved_quantity = promotion_price.reserved_quantity
                new_promotion_price_reserved_quantity = promotion_price.reserved_quantity + new_quantity
                need_to_update_promotion_price_reserved_quantity = true
                log = "#{sku_info} 原价库存由 #{old_promotion_price_reserved_quantity} 改为 #{new_promotion_price_reserved_quantity}"
              end
            elsif new_quantity.negative?
              # 调拨出库必须小于 OMS 现有总库存，不足时必须失败；
              # 足够时优先扣减原价库存，再扣减限时优惠库存
              abs_new_quantity = new_quantity.abs
              old_promotion_price_reserved_quantity = promotion_price.reserved_quantity
              total_quantity = old_promotion_price_reserved_quantity + sku.quantity

              if total_quantity >= abs_new_quantity
                if promotion_price.reserved_quantity >= abs_new_quantity
                  # 原价库存足够时直接扣减
                  new_promotion_price_reserved_quantity = old_promotion_price_reserved_quantity - abs_new_quantity
                  need_to_update_promotion_price_reserved_quantity = true
                  log = "#{sku_info} 原价库存由 #{old_promotion_price_reserved_quantity} 改为 #{new_promotion_price_reserved_quantity}"
                else
                  # 原价库存不够时从优惠价库存扣减
                  new_promotion_price_reserved_quantity = 0
                  need_to_update_promotion_price_reserved_quantity = true
                  sku.quantity = total_quantity - abs_new_quantity

                  log = sku_info +
                    "原价库存由 #{old_promotion_price_reserved_quantity} 改为 0, " +
                    "优惠库存由 #{old_sku_quantity} 改为 #{sku.quantity}"
                end
              else
                error = "#{sku_info} 调拨库存不足，差#{abs_new_quantity - total_quantity}个"
              end
            end
          else
            error = "SKU #{sku.no} 有多个激活的限时优惠，请处理后再更新库存"
          end

          OpenStruct.new(
            error: error,
            log: log,
            need_to_update_promotion_price_reserved_quantity: need_to_update_promotion_price_reserved_quantity,
            new_promotion_price_reserved_quantity: new_promotion_price_reserved_quantity,
            promotion_price: promotion_price
          )
        end
      end

      desc "取得当天最新的所有商品", {
        success: API::Entities::StockKeepingUnit,
        is_array: true
      }
      paginate
      params do
        use :sign_params
        optional :order_by, type: String, desc: "'created_at desc, updated_at asc' 多字段使用,隔开"
        optional :store_id, as: :store_id_eq, type: Integer, desc: "分店id"
        optional :id_in, type: Array[Integer], desc: "ID 数组"
      end
      get do
        params[:item_item_type_in] = [:normal, :same_day_delivery] # 只返回普通商品，不同步拍卖商品
        params[:item_ae_drop_shipper_eq] = false # 只返回自营商品，不同步跨境购商品
        @collection = end_of_association_chain.includes(:store, item: [:category, :brand, :on_sale_skus, category: :parent]).ransack(ransack_params)
        order_by = params[:order_by].split(",").map(&:strip).compact if params[:order_by].present?
        @collection.sorts = order_by || default_order

        @collection = @collection.result
        response_collection
      end

      desc "批量增加/减少商品库存", {
        success: API::Entities::StockKeepingUnit,
        is_array: true
      }
      paginate
      params do
        use :sign_params
        requires :stock_keeping_units, type: Array do
          requires :sku, type: String, desc: "sku"
          requires :product_id, type: Integer, desc: "OMS sku id"
          requires :quantity, type: Integer, desc: "库存增量"
          requires :store_id, type: Integer, desc: "Store Id"
        end
      end
      post "batch_update_quantity" do
        errors = []
        log_messages_hash = {}
        MagicBean::StockKeepingUnit.transaction do
          if params[:stock_keeping_units].any?
            params[:stock_keeping_units].each do |sku_params|
              begin
                sku_id = sku_params[:product_id]
                sku_no = sku_params[:sku]&.strip
                new_quantity = sku_params[:quantity].to_i

                sku = end_of_association_chain.where(store_id: sku_params[:store_id] || -1).find_by(id: sku_id)
                sku = end_of_association_chain.where(store_id: sku_params[:store_id] || -1).find_by(no: sku_no) if sku.blank?
                next if sku.nil?

                result = calculate_sku_quantity_change(new_quantity, sku)

                if result.error.present?
                  errors << result.error
                  next
                end

                if result.need_to_update_promotion_price_reserved_quantity
                  result.promotion_price.update_attribute :reserved_quantity, result.new_promotion_price_reserved_quantity
                end

                if sku.save!
                  log_messages_hash["#{sku.store_id}"] ||= []
                  log_messages_hash["#{sku.store_id}"] << result.log if sku.quantity_previously_changed? || result.need_to_update_promotion_price_reserved_quantity
                end
              rescue ActiveRecord::RecordInvalid => e
                errors << "sku: #{e.record.no}: #{e.message}"
              end
            end
          end

          raise ActiveRecord::Rollback if errors.any?
        end

        if errors.any?
          response_error errors.join(";")
        else
          log_messages_hash.each do |store_id, log_messages|
            log_messages.each_slice(50) do |part_messages|
              MagicBean::OperationRecord.create(content: part_messages.join("; "), store_id: store_id, channel: "wms")
            end
          end

          response_success
        end
      end

      desc "批量增加商品库存v2", {
        success: API::Entities::StockKeepingUnit,
        is_array: true,
        detail: <<-NOTES.strip_heredoc
        ```json
        {
          "results": [
            {
                "po_id": 1,
                "result": "success",
                "message": "success"
            },
            {
                "po_id": 2,
                "result": "failure",
                "message": "数量必须大于或等于 0"
            },
            {
                "po_id": 3,
                "result": "failure",
                "message": "找不到该sku"
            }
          ]
        }
        ```
        NOTES
      }
      paginate
      params do
        use :sign_params
        requires :stock_keeping_units, type: Array do
          requires :po_id, type: Integer, desc: "po_id"
          requires :sku, type: String, desc: "sku"
          requires :quantity, type: Integer, desc: "库存增量"
          requires :store_id, type: Integer, desc: "Store Id"
          requires :barcode, type: String, desc: "多个barcode使用,隔开"
          requires :supplier_name, type: String, desc: "供应商名称"
          requires :supplier_cost_in_cent, type: Integer, desc: "供应商价格(分)"
          optional :short_title, type: String, desc: "产品短标题"
          optional :gst_percent, type: Integer, desc: "GST%"
          optional :marketing_mode, type: String, values: ["self_support", "consign_for_sale"], desc: "营销模式，self_support：自营，consign_for_sale：寄售"
        end
      end
      post "batch_update_quantity_v2" do
        results = []
        log_messages_hash = {}

        if params[:stock_keeping_units].any?
          params[:stock_keeping_units].each do |sku_params|
            error = []
            po_id = sku_params[:po_id]
            result = { po_id: po_id }
            sku_no = sku_params[:sku]&.strip
            barcode = sku_params[:barcode]&.strip
            short_title = sku_params[:short_title]&.strip
            gst_percent = sku_params[:gst_percent]
            marketing_mode = sku_params[:marketing_mode]&.strip
            new_quantity = sku_params[:quantity].to_i

            sku = end_of_association_chain.where(store_id: sku_params[:store_id] || -1).find_by(no: sku_no)
            if sku.nil?
              results << result.merge!({ result: "failure", message: "找不到该sku" })
              next
            end
            sku.transaction do
              # 保存sku，若失败则纪录错误
              sku.barcode = barcode if sku.barcode.blank?
              sku.gst_percent = gst_percent if gst_percent.present?
              sku.marketing_mode = marketing_mode if marketing_mode.present?

              # 计算库存变动
              tmp_result = calculate_sku_quantity_change(new_quantity, sku)

              if tmp_result.error.present?
                error << tmp_result.error
                next
              end

              if tmp_result.need_to_update_promotion_price_reserved_quantity
                tmp_result.promotion_price.update_attribute :reserved_quantity, tmp_result.new_promotion_price_reserved_quantity
              end

              error << sku.errors.full_messages unless sku.save

              supplier_name = sku_params[:supplier_name].to_s.strip
              if supplier_name.present? && !supplier_name.casecmp?(MagicBean::Supplier::IGNORED_SUPPLIER_NAME)
                supplier = sku.suppliers.find_or_initialize_by(name: supplier_name)
                supplier.cost_in_cent = sku_params[:supplier_cost_in_cent]

                if supplier.changed?
                  # 保存supplier，若失败则纪录错误
                  error << supplier.errors.full_messages unless supplier.save
                else
                  # 如果进货价没变化，也要更新updated_at
                  supplier.touch
                end
              end

              # 修改短标题
              if short_title.present?
                item = sku.item
                item.short_title = short_title
                if item.save
                  item.product.update(short_title: short_title) if item.product && item.product.store_id == item.store_id
                else
                  error << item.errors.full_messages
                end
              end

              # sku 与 supplier 需在同一个事务中
              if error.any?
                raise ActiveRecord::Rollback
              else
                log_messages_hash["#{sku.store_id}"] ||= []
                log_messages_hash["#{sku.store_id}"] << tmp_result.log if sku.quantity_previously_changed? || tmp_result.need_to_update_promotion_price_reserved_quantity
              end
            end
            result.merge!(error.any? ? { result: "failure", message: error.join(";") } : { result: "success", message: "success" })
            results << result
          end
        end

        log_messages_hash.each do |store_id, log_messages|
          # 为避免内容太长，对log_messages进行分割
          log_messages.each_slice(50) do |part_messages|
            MagicBean::OperationRecord.create(content: part_messages.join("; "), store_id: store_id, channel: "wms")
          end
        end

        { results: results }
      end

      desc "批量增加商品库存v3, 新WMS用", {
        success: API::Entities::StockKeepingUnit,
        is_array: true,
        detail: <<-NOTES.strip_heredoc
        ```json
        {
          "results": [
            {
                "po_id": 1,
                "result": "success",
                "message": "success"
            },
            {
                "po_id": 2,
                "result": "failure",
                "message": "数量必须大于或等于 0"
            },
            {
                "po_id": 3,
                "result": "failure",
                "message": "找不到该sku"
            }
          ]
        }
        ```
        NOTES
      }
      paginate
      params do
        use :sign_params
        requires :stock_keeping_units, type: Array do
          requires :po_id, type: Integer, desc: "po_id"
          requires :product_id, type: Integer, desc: "OMS sku id"
          requires :sku, type: String, desc: "sku"
          requires :quantity, type: Integer, desc: "库存增量"
          requires :store_id, type: Integer, desc: "Store Id"
          requires :barcode, type: String, desc: "多个barcode使用,隔开"
          requires :supplier_name, type: String, desc: "供应商名称"
          requires :supplier_cost_in_cent, type: Integer, desc: "供应商价格(分)"
          optional :po_number, type: String, desc: "PO单号"
          optional :short_title, type: String, desc: "产品短标题"
          optional :gst_percent, type: Integer, desc: "GST%"
          optional :marketing_mode, type: String, values: ["self_support", "consign_for_sale", "platform"], desc: "营销模式，self_support：自营，consign_for_sale：寄售，platform：平台"
          optional :inc_gst, type: Boolean, desc: "是否包含GST"
          optional :gst, type: String, desc: "GST金额(元)"
        end
      end
      post "batch_update_quantity_v3" do
        results = []
        log_messages_hash = {}

        if params[:stock_keeping_units].any?
          params[:stock_keeping_units].each do |sku_params|
            begin
              error = []
              po_id = sku_params[:po_id]
              po_number = sku_params[:po_number]&.strip
              sku_id = sku_params[:product_id]
              result = { po_id: po_id }
              sku_no = sku_params[:sku]&.strip
              barcode = sku_params[:barcode]&.strip
              short_title = sku_params[:short_title]&.strip
              gst_percent = sku_params[:gst_percent]
              marketing_mode = sku_params[:marketing_mode]&.strip
              new_quantity = sku_params[:quantity].to_i

              sku = end_of_association_chain.where(store_id: sku_params[:store_id] || -1).find_by(id: sku_id)
              sku = end_of_association_chain.where(store_id: sku_params[:store_id] || -1).find_by(no: sku_no) if sku.blank?

              if sku.nil?
                results << result.merge!({ result: "failure", message: "找不到该sku" })
                next
              end
              sku.transaction do
                # 保存sku，若失败则纪录错误
                sku.barcode = barcode if sku.barcode.blank?
                sku.gst_percent = gst_percent if gst_percent.present?
                sku.marketing_mode = marketing_mode if marketing_mode.present?

                # 计算库存变动
                tmp_result = calculate_sku_quantity_change(new_quantity, sku)

                if tmp_result.error.present?
                  error << tmp_result.error
                  next
                end

                if tmp_result.need_to_update_promotion_price_reserved_quantity
                  tmp_result.promotion_price.update_attribute :reserved_quantity, tmp_result.new_promotion_price_reserved_quantity
                end

                error << sku.errors.full_messages unless sku.save

                supplier_name = sku_params[:supplier_name].to_s.strip
                if !supplier_name.casecmp?(MagicBean::Supplier::IGNORED_SUPPLIER_NAME)
                  supplier = sku.suppliers.find_or_initialize_by(name: supplier_name)
                  supplier.cost_in_cent = sku_params[:supplier_cost_in_cent]
                  supplier.include_gst = sku_params[:inc_gst]
                  supplier.gst_amount = sku_params[:gst]

                  if supplier.changed?
                    # 保存supplier，若失败则纪录错误
                    error << supplier.errors.full_messages unless supplier.save
                  else
                    # 如果进货价没变化，也要更新updated_at
                    supplier.touch
                  end
                end

                # 修改短标题
                if short_title.present?
                  item = sku.item
                  item.short_title = short_title
                  if item.save
                    item.product.update(short_title: short_title) if item.product && item.product.store_id == item.store_id
                  else
                    error << item.errors.full_messages
                  end
                end

                # sku 与 supplier 需在同一个事务中
                if error.any?
                  raise ActiveRecord::Rollback
                else
                  log_messages_hash["#{sku.store_id}"] ||= []
                  log_messages_hash["#{sku.store_id}"] << "PO单号：#{po_number}, #{tmp_result.log}" if sku.quantity_previously_changed? || tmp_result.need_to_update_promotion_price_reserved_quantity
                end
              end
              result.merge!(error.any? ? { result: "failure", message: error.join(";") } : { result: "success", message: "success" })
              results << result
            rescue => e
              # 捕获事务外的其他异常，避免500错误，包含sku_no信息
              error_message = "SKU 处理异常: #{e.message}"
              results << { po_id: sku_params[:po_id], result: "failure", message: error_message }
            end
          end
        end

        log_messages_hash.each do |store_id, log_messages|
          # 为避免内容太长，对log_messages进行分割
          log_messages.each_slice(50) do |part_messages|
            MagicBean::OperationRecord.create(content: part_messages.join("; "), store_id: store_id, channel: "wms")
          end
        end

        { results: results }
      end

      route_param :sku, type: String, desc: "sku id" do
        desc "更新 SKU", {
          success: API::Entities::StockKeepingUnit
        }
        params do
          use :sign_params
          requires :short_title, type: String, desc: "产品短标题"
        end
        put do
          @resource = end_of_association_chain.find_by(no: params[:sku])

          @resource.transaction do
            item = @resource.item
            product = item.product
            short_title = params[:short_title]

            item.update_attribute :short_title, short_title
            product.update_attribute :short_title, short_title

            response_resource
          end

        rescue StandardError => e
          response_error(e.message)
        end
      end
    end
  end
end
