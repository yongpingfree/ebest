# frozen_string_literal: true

module BeansAdmin
  class API::V1::Items < ::API

    namespace :items, desc: "商品 API" do
      helpers BeansAdmin::Helpers::FileUploadHelper

      helpers do
        def permitted_params
          @permitted_params = resource_class.globalize_attribute_names + [
            :sub_title, :short_title, :cover, :share_cover, :category_id, :minor_category_id, :gift_card_enabled, :not_eligible_for_free_gift, :leader, :gift_only, :ae_category_id,
            :qa_and_guarantee_id, :brand_id, :store_id, :detail_video, :monthly_sales_count_offset, :sales_count_offset, :top_left_corner_tag_image,
            :start_selling_at, :fixed_freight_cost, :fixed_freight_cost_in_yuan, :coupon_enabled, :translated_searchable_title, :production_place,
            :likes_count_offset, :buy_quota, :buy_quota_days, :product_id, :translated_searchable_description, :allergen, :ingredient,
            :item_type, :listing_type, :no, :freight_type, :fixed_freight, :freight_template_id, :storage_method, :free_shipping,
            :is_presell, :presell_end_at, :presell_dispatch_on, :latest_presell_dispatch_on, :is_virtual, :serving_per_package, :serving_size, :same_day_delivery, :is_seasonal, :is_fresh_daily,
            :show_expiration_date, :days_ahead_to_show_expiration, :web_category_id, :minor_web_category_id, :expiration_reminder_before_n_days,
            main_images: [], detail_images: [], delivery_type: [], default_freight_template_ids: [], channels: [],
            stock_keeping_units_attributes: [
              :id, :properties, :price_in_yuan, :strikethrough_price_in_yuan, :new_user_price_in_yuan, :new_user_buy_quota, :no, :quantity, :gst_percent,
              :cost_price_in_yuan, :image, :weight_in_gram, :_destroy, :marketing_mode, :shoppingunit, :is_special, :is_private_kitchen, :shopline_price_in_yuan, :ae_price_in_yuan,
              :barcode, :length_in_cm, :width_in_cm, :height_in_cm, :on_sale, :carton_size, :discount_quantity, :discount_price_in_yuan, :is_box_regulation,
              groups: [:id, :type, :quantity]
            ],
            tag_list: [],
            comment_tag_list: [],
            cutoff_times_attributes: [
              :id, :_destroy, :deliver_after_n_days, time_at: [], weekdays: []
            ],
            delivery_weekdays: []
          ]

          @permitted_params += [
            product_attributes: [
              :id, :title, :sub_title, :short_title, :description, :shared_description, :cover, :share_cover, :category_id, :minor_category_id, :qa_and_guarantee_id,
              :brand_id, :store_id, :detail_video, :monthly_sales_count_offset, :sales_count_offset, detail_images: [], main_images: []
            ]
          ] if request.env["REQUEST_METHOD"].eql?("POST") || current_admin_user.super_admin? || current_store_id == resource&.store_id
          @permitted_params
        end

        def set_product_params
          # set product store if nil
          params[:product_attributes] ||= {}
          params[:product_attributes][:store_id] ||= params[:store_id]
          params[:product_attributes][:id] ||= params[:product_id]
          params[:product_attributes][:title] ||= params[:title_zh_cn]
          params[:product_attributes][:sub_title] ||= params[:title_en]
          params[:product_attributes][:short_title] ||= params[:short_title]
          params[:product_attributes][:description] ||= params[:description_zh_cn]
          params[:product_attributes][:shared_description] ||= params[:shared_description_zh_cn]
          params[:product_attributes][:cover] ||= params[:cover]
          params[:product_attributes][:share_cover] ||= params[:share_cover]
          params[:product_attributes][:category_id] ||= params[:category_id]
          params[:product_attributes][:minor_category_id] ||= params[:minor_category_id]
          params[:product_attributes][:brand_id] ||= params[:brand_id]
          params[:product_attributes][:detail_video] ||= params[:detail_video]
          params[:product_attributes][:sales_count_offset] ||= params[:sales_count_offset]
          params[:product_attributes][:detail_images] ||= params[:detail_images]
          params[:product_attributes][:main_images] ||= params[:main_images]
          params[:product_attributes][:qa_and_guarantee_id] ||= params[:qa_and_guarantee_id]
        end

        def default_order
          ["created_at DESC"]
        end

        def includes
          [:store, :translations, :shopline_item, category: [:translations], minor_category: [:translations], brand: [:translations], web_category: [:translations]]
        end

        def end_of_association_chain
          resource_class.not_deleted
        end
      end

      desc "商品列表", {
        success: API::Entities::SimpleItem,
        is_array: true
      }
      paginate
      params do
        optional :order_by, type: String, desc: "排序"
        optional :keyword, as: :translated_searchable_title_or_short_title_cont_any, type: String, desc: "搜索商品标题、短标题"
        optional :item_type_eq, type: String, desc: "商品类型", values: ->() { MagicBean::Item.item_types.keys }
        optional :parent_category_id_eq, type: Integer, desc: "一级分类ID"
        optional :category_id_eq, type: Integer, desc: "主商品分类"
        optional :web_category_id_eq, type: Integer, desc: "网站主商品分类"
        optional :minor_category_id_eq, type: Integer, desc: "次商品分类"
        optional :minor_web_category_id_eq, type: Integer, desc: "次商品分类"
        optional :info_type, type: String, desc: "信息类型，不传则返回全部信息，传 simple 则返回简要信息"
        optional :on_sale, type: Grape::API::Boolean, desc: "在售商品"
        optional :delivery_type, types: Array, values: ->() { MagicBean::Item::DELIVERY_TYPE_ARRAY }
        optional :channels, types: Array, values: ->() { MagicBean::Item::CHANNEL_ARRAY + MagicBean::Item::THIRD_PART_CHANNEL_ARRAY }
      end
      get do
        authorize! :read, resource_class
        params["parent_category_id_in"] = current_user.can_read_category_ids

        where_params = { item_type: [:normal, :same_day_delivery] }
        where_params[:ae_drop_shipper] = false unless params[:ae_drop_shipper_eq] == "all"

        @collection = end_of_association_chain.where(where_params).accessible_by(current_ability)

        @collection = @collection.delivery_type_contains(params[:delivery_type]) if params[:delivery_type].present?
        @collection = @collection.channels_contains_any(params[:channels]) if params[:channels].present?

        @collection = @collection.on_sale if params[:on_sale].present?
        items = @collection
          .includes(includes)
          .ransack(ransack_params)

        order_by = (params[:order_by].split(",").map(&:strip).compact + default_order).uniq if params[:order_by].present?
        items.sorts = order_by || default_order
        items = items.result.distinct

        response_items = paginate(items)

        item_product_hash = {}
        item_ids, not_destroyable_item_ids = [], []

        response_items.each do |item|
          item_ids << item.id
          item_product_hash[item.product_id] ||= []
          item_product_hash[item.product_id] << { item_id: item.id, store_id: item.store_id }
        end

        MagicBean::Product.where(id: item_product_hash.keys).where("items_count > 1").each do |product|
          item_product_hash[product.id].each do |item|
            not_destroyable_item_ids << item[:item_id] if item[:store_id] == product.store_id
          end
        end

        not_destroyable_item_ids = (not_destroyable_item_ids + MagicBean::OrderItem.where(item_id: item_ids).pluck(:item_id)).uniq

        present response_items, with: API::Entities::SimpleItem, not_destroyable_item_ids: not_destroyable_item_ids
      end

      desc "AE 商品列表", {
        success: API::Entities::SimpleItem,
        is_array: true
      }
      paginate
      params do
        optional :order_by, type: String, desc: "排序"
        optional :keyword, as: :translated_searchable_title_or_short_title_cont_any, type: String, desc: "搜索商品标题、短标题"
        optional :item_type_eq, type: String, desc: "商品类型", values: ->() { MagicBean::Item.item_types.keys }
        optional :parent_category_id_eq, type: Integer, desc: "一级分类ID"
        optional :category_id_eq, type: Integer, desc: "主商品分类"
        optional :web_category_id_eq, type: Integer, desc: "网站主商品分类"
        optional :minor_category_id_eq, type: Integer, desc: "次商品分类"
        optional :minor_web_category_id_eq, type: Integer, desc: "次商品分类"
        optional :info_type, type: String, desc: "信息类型，不传则返回全部信息，传 simple 则返回简要信息"
        optional :on_sale, type: Grape::API::Boolean, desc: "在售商品"
        optional :delivery_type, types: Array, values: ->() { MagicBean::Item::DELIVERY_TYPE_ARRAY }
        optional :channels, types: Array, values: ->() { MagicBean::Item::CHANNEL_ARRAY + MagicBean::Item::THIRD_PART_CHANNEL_ARRAY }
      end
      get "aliexpress" do
        raise CanCan::AccessDenied unless current_user.permissions.include?("ae_items")
        params["category_parent_id_in"] = current_user.can_read_category_ids

        @collection =  @collection = end_of_association_chain.where(item_type: [:normal, :same_day_delivery], ae_drop_shipper: true)

        @collection = @collection.delivery_type_contains(params[:delivery_type]) if params[:delivery_type].present?
        @collection = @collection.channels_contains_any(params[:channels]) if params[:channels].present?

        @collection = @collection.on_sale if params[:on_sale].present?
        items = @collection
          .includes(includes)
          .ransack(ransack_params)

        order_by = (params[:order_by].split(",").map(&:strip).compact + default_order).uniq if params[:order_by].present?
        items.sorts = order_by || default_order
        items = items.result.distinct

        response_items = paginate(items)

        item_product_hash = {}
        item_ids, not_destroyable_item_ids = [], []

        response_items.each do |item|
          item_ids << item.id
          item_product_hash[item.product_id] ||= []
          item_product_hash[item.product_id] << { item_id: item.id, store_id: item.store_id }
        end

        MagicBean::Product.where(id: item_product_hash.keys).where("items_count > 1").each do |product|
          item_product_hash[product.id].each do |item|
            not_destroyable_item_ids << item[:item_id] if item[:store_id] == product.store_id
          end
        end

        not_destroyable_item_ids = (not_destroyable_item_ids + MagicBean::OrderItem.where(item_id: item_ids).pluck(:item_id)).uniq

        present response_items, with: API::Entities::SimpleItem, not_destroyable_item_ids: not_destroyable_item_ids
      end

      desc "导出商品列表"
      params do
        optional :order_by, type: String, desc: "排序"
        optional :keyword, as: :translated_searchable_title_or_short_title_cont_any, type: String, desc: "搜索商品标题、英文标题"
        optional :item_type_eq, type: String, desc: "商品类型", values: ->() { MagicBean::Item.item_types.keys }
        optional :category_id_eq, type: Integer, desc: "主商品分类"
        optional :minor_category_id, type: Integer, desc: "次商品分类"
        optional :on_sale, type: Grape::API::Boolean, desc: "在售商品"
        optional :delivery_type, types: Array
      end
      get "export" do
        if params[:ae_drop_shipper_eq] == "true"
          raise CanCan::AccessDenied unless current_user.permissions.include?("ae_items")
        else
          authorize! :read, resource_class
        end

        response_error("您还没有设置邮箱。") if current_admin_user.email.nil?

        check_export_list_count

        params["parent_category_id_in"] = current_user.can_read_category_ids

        if params["category_ids"].present?
          params["parent_category_id_eq"], params["category_id_eq"] = params["category_ids"]
        end

        if params["minor_category_ids"].present?
          params["minor_category_parent_id_eq"], params["minor_category_id_eq"] = params["minor_category_ids"]
        end

        options = {
          email: current_admin_user.email,
          order_by: params[:order_by] || default_order,
          on_sale: params[:on_sale],
          delivery_type: params[:delivery_type],
          channels: params[:channels],
          ransack_params: ransack_params
        }

        options = encrypt_params(options)

        ExportItemsJob.perform_later(options)

        present({ message: "导出任务后台执行，请稍后查看邮箱。" })
      end

      desc "商品导入"
      params do
        requires :file_message, type: JSON, desc: "xlsx 文件信息"
      end
      post "import" do
        response_error("请选择 xlsx 文件") unless check_file_type(params[:file_message], "xlsx")

        error_messages = []

        xlsx = Roo::Spreadsheet.open params[:file_message]["tempfile"].path
        result = xlsx.sheet(0).parse(headers: true)

        MagicBean::Item.transaction do
          result[2..-1].each.with_index(3) do |row, i|
            item_attributes, item, err_message, log_messages = set_import_params(row)
            if err_message.present?
              error_messages << "第#{i}行: #{err_message.join("，")}"
              next
            end

            log_message = log_messages.join(", ")
            if item.present?
              if item.update(item_attributes)
                current_admin_user.operation_records.create(operatable: item, content: log_message, store_id: current_store_id) if log_message.present?
              else
                error_messages << "第#{i}行: #{item.errors.full_messages.join("，")}"
              end
            else
              resource = end_of_association_chain.new(item_attributes)
              if resource.save
                current_admin_user.operation_records.create(operatable: resource, content: log_message, store_id: current_store_id) if log_message.present?
              else
                error_messages << "第#{i}行: #{resource.errors.full_messages.join("，")}" unless resource.save
              end
            end
          end

          raise ActiveRecord::RecordInvalid if error_messages.present?
        end
        response_success
      rescue ActiveRecord::RecordInvalid => e
        response_error(error_messages.join("; "))
      rescue => e
        response_error(e.message)
      end

      desc "商品异步导入"
      params do
        requires :file_message, type: JSON, desc: "xlsx 文件信息"
      end
      post "async_import" do
        response_error("请选择 xlsx 文件") unless check_file_type(params[:file_message], "xlsx")

        file_path = params[:file_message]["tempfile"].path
        file_name = "async_import_items/#{Date.current.strftime("%y%m%d")}/#{File.basename(file_path)}"
        file_url = aws_upload!(file_path, file_name)

        ItemMailer.import(current_admin_user.email, file_url).deliver_later

        response_success
      end

      desc "商品基础信息异步导入"
      params do
        requires :file_message, type: JSON, desc: "xlsx 文件信息"
      end
      post "async_import_basic_info" do
        response_error("请选择 xlsx 文件") unless check_file_type(params[:file_message], "xlsx")

        file_path = params[:file_message]["tempfile"].path
        file_name = "async_import_items/#{Date.current.strftime("%y%m%d")}/#{File.basename(file_path)}"
        file_url = aws_upload!(file_path, file_name)

        ImportFromExcelAndNotifyJob.perform_later("MagicBean::Item", file_url, current_admin_user.id)

        response_success
      end

      desc "商品 SKU 信息异步导入"
      params do
        requires :file_message, type: JSON, desc: "xlsx 文件信息"
      end
      post "async_import_skus" do
        response_error("请选择 xlsx 文件") unless check_file_type(params[:file_message], "xlsx")

        file_path = params[:file_message]["tempfile"].path
        file_name = "async_import_skus/#{Date.current.strftime("%y%m%d")}/#{File.basename(file_path)}"
        file_url = aws_upload!(file_path, file_name)

        ImportFromExcelAndNotifyJob.perform_later("MagicBean::StockKeepingUnit", file_url, current_admin_user.id)

        response_success
      end

      desc "商品成分表异步导入"
      params do
        requires :file_message, type: JSON, desc: "xlsx 文件信息"
      end
      post "async_import_nutritions" do
        response_error("请选择 xlsx 文件") unless check_file_type(params[:file_message], "xlsx")

        file_path = params[:file_message]["tempfile"].path
        file_name = "async_import_nutritions/#{Date.current.strftime("%y%m%d")}/#{File.basename(file_path)}"
        file_url = aws_upload!(file_path, file_name)

        ImportFromExcelAndNotifyJob.perform_later("MagicBean::ItemNutritionValue", file_url, current_admin_user.id)

        response_success
      end

      desc "产品标签异步导入"
      params do
        requires :file_message, type: JSON, desc: "xlsx 文件信息"
      end
      post "async_import_tags" do
        response_error("请选择 xlsx 文件") unless check_file_type(params[:file_message], "xlsx")

        file_path = params[:file_message]["tempfile"].path
        file_name = "async_import_item_tags/#{Date.current.strftime("%y%m%d")}/#{File.basename(file_path)}"
        file_url = aws_upload!(file_path, file_name)

        ImportFromExcelAndNotifyJob.perform_later("MagicBean::ItemTag", file_url, current_admin_user.id)

        response_success
      end

      desc "创建商品", {
        success: API::Entities::Item
      }
      params do
        requires :all, using: API::Entities::Item.documentation.dup.extract!(:title_zh_cn, :description_zh_cn, :cover, :category_id, :brand_id, :detail_images, :main_images, :qa_and_guarantee_id, :buy_quota, :buy_quota_days, :listing_type, :delivery_type, :channels)
        optional :all, using: API::Entities::Item.documentation.dup.extract!(:sub_title, :short_title, :shared_description, :share_cover, :minor_category_id, :detail_video, :monthly_sales_count_offset, :start_selling_at, :no, :shared_description, :freight_template_id, :fixed_freight, :brand, :freight_type, :detail_video, :is_presell, :presell_end_at, :presell_dispatch_on, :latest_presell_dispatch_on, :product_id, :top_left_corner_tag_image, :is_virtual, :delivery_weekdays, :show_expiration_date, :days_ahead_to_show_expiration, :expiration_reminder_before_n_days)
        requires :stock_keeping_units_attributes, type: Array do
          # 使用model的来校验必填项，这里不再设置requires, grape再处理数组错误信息时有些麻烦，类似stock_keeping_units_attributes[0][no]，很难在yml里面处理
          optional :all, using: API::Entities::StockKeepingUnit.documentation
          optional :groups, type: Array do
            optional :id, type: Integer, desc: "产品或SKU ID"
            optional :type, type: String, values: ["MagicBean::Item", "MagicBean::StockKeepingUnit"], desc: "类型"
            optional :quantity, type: Integer, desc: "数量"
          end
        end
      end
      post do
        # 复制商品时不创建product
        set_product_params if params[:product_id].blank?
        authorize_and_create_resource
      rescue ActiveRecord::RecordNotUnique
        response_error("请检查sku货号不能重复")
      end

      desc "所有产品标签"
      params do
        optional :name_cont, type: String, desc: "搜索标签名"
      end
      paginate
      get "tags" do
        name_cont = params[:name_cont]
        tags = MagicBean::Item.all_tags

        if name_cont.present?
          present tags.ransack(name_cont: name_cont).result
        else
          present paginate(tags.order(id: :desc))
        end
      end

      desc "批量上/下架商品", {
        success: API::Entities::SuccessfulResult
      }
      params do
        requires :item_ids, type: Array[Integer], coerce_with: ->(val) { val.split(/[,]/).map(&:strip).map(&:to_i) }
        requires :to_listing_type, type: String
      end
      put "batch_confirm" do
        listing_type_name = params[:to_listing_type] == "online" ? "上架" : "下架"
        response_error "请选择可#{listing_type_name}的商品" if params[:item_ids].blank?
        items = MagicBean::Item.where(id: params[:item_ids])
        error_messages = []
        begin
          MagicBean::Item.transaction do
            items.each do |item|
              error_messages << "#{item.title} #{item.errors.full_messages.join(", ")}" unless item.update(listing_type: params[:to_listing_type])
            end

            raise ActiveRecord::RecordInvalid if error_messages.present?
          end

          if items.present?
            log_message = "批量#{listing_type_name}产品，设置的产品为：#{items.map { |item| item.title }.join("; ")}"
            current_admin_user.operation_records.create(content: log_message, store_id: current_store_id)
          end

          response_success
        rescue => _
          response_error(error_messages.join("; "))
        end
      end

      desc "批量设置搜索别用名", {
        success: API::Entities::SuccessfulResult
      }
      params do
        requires :item_ids, type: Array[Integer], coerce_with: ->(val) { val.split(/[,]/).map(&:strip).map(&:to_i) }
        requires :tag_list, type: Array[String]
      end
      put "batch_tags" do
        MagicBean::Item.where(id: params[:item_ids]).each do |item|
          item.tag_list.add(params[:tag_list])
          item.save
        end
        response_success
      end

      desc "批量设置上架时间", {
        success: API::Entities::SuccessfulResult
      }
      params do
        requires :item_ids, type: Array[Integer], coerce_with: ->(val) { val.split(/[,]/).map(&:strip).map(&:to_i) }
        requires :start_selling_at, type: DateTime
      end
      put "batch_start_selling_at" do
        items = MagicBean::Item.where(id: params[:item_ids])

        error_messages = []
        begin
          MagicBean::Item.transaction do
            items.each do |item|
              error_messages << "#{item.title} #{item.errors.full_messages.join(", ")}" unless item.update(start_selling_at: params[:start_selling_at], listing_type: :advance_on)
            end

            raise ActiveRecord::RecordInvalid if error_messages.present?
          end

          if items.present?
            log_message = "批量设置开卖时间为#{params[:start_selling_at]}，设置的产品为：#{items.map { |item| item.title }.join("; ")}"
            current_admin_user.operation_records.create(content: log_message, store_id: current_store_id)
          end

          response_success
        rescue => _
          response_error(error_messages.join("; "))
        end
      end

      desc "用户浏览记录", {
        success: API::Entities::Item,
        is_array: true
      }
      params do
        optional :title_cont, type: String, desc: "标题"
        optional :order_by, type: String, desc: "排序"
        optional :parent_category_id_eq, type: Integer, desc: "一级分类ID"
        optional :category_id_eq, type: Integer, desc: "主商品分类"
        optional :minor_category_id, type: Integer, desc: "次商品分类"
      end
      paginate
      get "histories" do
        item_created_at_range = ((params[:item_created_at_gteq]&.to_datetime || DateTime.new(2019)).in_time_zone.beginning_of_day)..(params[:item_created_at_lteq]&.to_datetime&.in_time_zone&.end_of_day || DateTime::Infinity.new)
        history_created_at_end_at = (params[:history_created_at_end]&.to_datetime&.in_time_zone || Time.current)&.end_of_day
        history_created_at_start_at = (params[:history_created_at_start]&.to_datetime || history_created_at_end_at - 1.month).in_time_zone.beginning_of_day
        @collection = end_of_association_chain.accessible_by(current_ability)
                        .where(created_at: item_created_at_range)
                        .select("items.*, count(distinct histories.operator_id) as user_views_count, count(histories.id) as page_views_count")
                        .joins("LEFT OUTER JOIN histories ON histories.operatable_id = items.id AND histories.operatable_type = 'MagicBean::Item' AND histories.action_type = 0 AND histories.created_at between '#{history_created_at_start_at}' and '#{history_created_at_end_at}'")
                        .ransack(ransack_params)
        order_by = if params[:order_by].present?
                     (::BeansAdmin::Helpers::OrderBySanitizer.sanitize_fragments(params[:order_by]) + default_order).uniq
                   else
                     default_order
                   end.join(", ")

        present paginate(@collection.result.group(:id).reorder(order_by)), with: API::Entities::ItemHistory
      end

      desc "赠品统计"
      params do
        optional :barcode_or_no_eq, type: String, desc: "SKU barcode或no"
        optional :delivery_start_date, type: Date, desc: "发货开始日期"
        optional :delivery_end_date, type: Date, desc: "发货结束日期"
      end
      get "gift_data" do
        raise CanCan::AccessDenied unless current_user.permissions.include?("gift_orders_analyses")

        blank_params_count = [params[:delivery_start_date], params[:delivery_end_date]].select(&:blank?).count

        # 默认列表不报错
        return [] if params[:barcode_or_no_eq].blank? && blank_params_count == 2

        response_error("发货开始日期和结束日期必选") if blank_params_count > 0

        delivery_dates = params[:delivery_start_date].to_date..params[:delivery_end_date].to_date

        collection = MagicBean::Order.paid.where(delivery_date: delivery_dates).where.not(gifts_properties: nil).ransack({ store_id_eq: current_store_id }).result

        sku = nil

        if params[:barcode_or_no_eq]
          sku = MagicBean::StockKeepingUnit.ransack({ barcode_or_no_eq: params[:barcode_or_no_eq], store_id_eq: current_store_id }).result.first
          response_error("请输入正确的UPC/SKU") if sku.blank?
          collection = collection.where("EXISTS (SELECT FROM json_array_elements(orders.gifts_properties) gift_element WHERE (gift_element->>'stock_keeping_unit_id')::int = #{sku.id})")
        end

        hash = {}

        collection.each do |order|
          order.gifts_properties.each do |gift|
            next if sku && gift["stock_keeping_unit_id"] != sku.id
            hash["#{gift["stock_keeping_unit_id"]}"] ||= gift.merge({ gift_count: 0 })
            hash["#{gift["stock_keeping_unit_id"]}"][:gift_count] += gift["quantity"]
          end
        end

        MagicBean::StockKeepingUnit.includes(:newest_supplier).where(id: hash.keys).each do |sku|
          hash["#{sku.id}"].merge!({ barcode: sku.barcode, supplier_name: sku&.newest_supplier&.name, cost_in_cent: sku&.newest_supplier&.cost_in_cent, cost_in_yuan: sku&.newest_supplier&.cost_in_yuan })
          hash["#{sku.id}"]["price_in_cent"] = sku.final_price(1).first
          hash["#{sku.id}"]["price_in_yuan"] = sku.final_price(1).last
        end

        hash.values
      end

      desc "优惠池赠品统计"
      params do
        optional :barcode_or_no_eq, type: String, desc: "SKU barcode或no"
        optional :delivery_start_date, type: Date, desc: "发货开始日期"
        optional :delivery_end_date, type: Date, desc: "发货结束日期"
      end
      get "pool_gift_data" do
        raise CanCan::AccessDenied unless current_user.permissions.include?("pool_gift_orders_analyses")
        blank_params_count = [params[:delivery_start_date], params[:delivery_end_date]].select(&:blank?).count

        # 默认列表不报错
        return [] if params[:barcode_or_no_eq].blank? && blank_params_count == 2

        response_error("发货开始日期和结束日期必选") if blank_params_count > 0

        delivery_dates = params[:delivery_start_date].to_date..params[:delivery_end_date].to_date

        collection = MagicBean::Order.paid.where(delivery_date: delivery_dates).where.not(pool_gifts_properties: nil).ransack({ store_id_eq: current_store_id }).result

        sku = nil

        if params[:barcode_or_no_eq]
          sku = MagicBean::StockKeepingUnit.ransack({ barcode_or_no_eq: params[:barcode_or_no_eq], store_id_eq: current_store_id }).result.first
          response_error("请输入正确的UPC/SKU") if sku.blank?
          collection = collection.where("EXISTS (SELECT FROM json_array_elements(orders.pool_gifts_properties) gift_element WHERE (gift_element->>'stock_keeping_unit_id')::int = #{sku.id})")
        end

        hash = {}

        collection.each do |order|
          order.pool_gifts_properties.each do |gift|
            next if sku && gift["stock_keeping_unit_id"] != sku.id
            hash["#{gift["stock_keeping_unit_id"]}"] ||= gift.merge({ gift_count: 0 })
            hash["#{gift["stock_keeping_unit_id"]}"][:gift_count] += gift["quantity"]
          end
        end

        MagicBean::StockKeepingUnit.includes(:newest_supplier).where(id: hash.keys).each do |sku|
          hash["#{sku.id}"].merge!({ barcode: sku.barcode, supplier_name: sku&.newest_supplier&.name, cost_in_cent: sku&.newest_supplier&.cost_in_cent, cost_in_yuan: sku&.newest_supplier&.cost_in_yuan })
          hash["#{sku.id}"]["price_in_cent"] = sku.final_price(1).first
          hash["#{sku.id}"]["price_in_yuan"] = sku.final_price(1).last
        end

        hash.values
      end

      desc "获取所有产品负责人"
      get "leaders" do
        MagicBean::Item.all.pluck(:leader).flatten.uniq
      end

      desc "获取指定商品标签数据"
      params do
        requires :ids, type: Array, desc: "商品ID"
      end
      get "item_tags" do
        item_tags_count = MagicBean::ItemTagRelation.where(item_id: params[:ids]).group(:item_tag_id).count

        # 所有产品共同标签
        common_tags = item_tags_count.select { |item_tag_id, count| count == params[:ids].count }
        
        # 获取所有产品都可查看产品的标签
        all_allow_view_tag_id = MagicBean::ItemTagRelation.where(item_id: params[:ids], item_tag_id: common_tags.keys, allow_view_same_tag_items: true).first&.item_tag_id

        MagicBean::ItemTag.includes(:translations).where(id: item_tags_count.keys).map do |item_tag|
          {
            id: item_tag.id,
            name: item_tag.name,
            tag_count: item_tags_count[item_tag.id],
            all_allow_view_same_tag_items: item_tag.id == all_allow_view_tag_id
          }
        end
      end

      desc "批量更新商品标签"
      params do
        requires :item_ids, type: Array, desc: "商品ID"
        optional :item_tag_ids, type: Array, desc: "商品标签ID"
        optional :view_same_tag_items_tag_id, type: Integer, desc: "可查看相同标签商品的标签ID"
        optional :remove_item_tag_ids, type: Array, desc: "移除的商品标签ID"
      end
      put "batch_update_item_tags" do
        # 移除商品标签，update_all不会触发counter_cache，需要重新计算标签数量
        if params[:remove_item_tag_ids].present?
          MagicBean::ItemTagRelation.where(item_id: params[:item_ids]).where(item_tag_id: params[:remove_item_tag_ids]).delete_all
          MagicBean::ItemTag.includes(:item_tag_relations).where(id: params[:remove_item_tag_ids]).each { |item_tag| item_tag.recalculate_tag_count }
        end
        
        # 批量创建商品标签
        (params[:item_tag_ids] || []).each do |item_tag_id|
          params[:item_ids].each do |item_id|
            MagicBean::ItemTagRelation.find_or_create_by!(item_id: item_id, item_tag_id: item_tag_id)
          end
        end

        # 每个产品可查看相同标签商品的标签只能设置一个
        if params[:view_same_tag_items_tag_id].present?
          MagicBean::ItemTagRelation.where(item_id: params[:item_ids]).where.not(item_tag_id: params[:view_same_tag_items_tag_id]).update_all(allow_view_same_tag_items: false)
          MagicBean::ItemTagRelation.where(item_id: params[:item_ids]).where(item_tag_id: params[:view_same_tag_items_tag_id]).update_all(allow_view_same_tag_items: true)
        end

        response_success
      end

      route_param :id do
        desc "商品详情", {
          success: API::Entities::Item
        }
        params do
          optional :entity_type, type: String, values: ["only_basic_item", "only_skus"], desc: "only_basic_item只获取产品基础信息，only_skus只获取产品规格信息, 不传则获取完整信息"
        end
        get do
          if resource.ae_drop_shipper
            raise CanCan::AccessDenied unless current_user.permissions.include?("ae_items")
          else
            authorize! :read, resource
          end

          entity = if params[:entity_type] == "only_basic_item"
                     API::Entities::ItemWithoutSku
                   elsif params[:entity_type] == "only_skus"
                     API::Entities::ItemOnlyWithSku
                   else
                     API::Entities::Item
                   end

          sku_nos = resource.stock_keeping_units.pluck(:no)
          sale_quantities = {}
          # 统计shopline待确认订单的sku数量
          MagicBean::ThirdPartyOrder.shopline.pending.where("delivery_date >= ?", Date.current.to_s).where(store_id: resource.store_id).find_each do |order|
            order.order_items.each do |order_item|
              next unless order_item["sku"].in?(sku_nos)
    
              sale_quantities["#{order_item["sku"]}"] ||= 0
              sale_quantities["#{order_item["sku"]}"] += order_item["quantity"]
            end
          end

          response_resource(present: { with: entity }, params: { item: resource, sale_quantities: sale_quantities })
        end

        desc "修改商品", {
          success: API::Entities::Item,
          skip_store_id: true
        }
        params do
          optional :all, using: API::Entities::Item.documentation.dup.extract!(
            :category_id, :minor_category_id, :title, :short_title, :main_images, :detail_images, :likes_count_offset, :leader, :gift_only,
            :monthly_sales_count_offset, :buy_quota, :buy_quota_days, :description, :shared_description, :item_type, :listing_type,
            :start_selling_at, :freight_type, :freight_template_id, :fixed_freight, :qa_and_guarantee_id, :brand_id,
            :sub_title, :cover, :share_cover, :delivery_type, :default_freight_template_ids, :detail_video,
            :is_presell, :presell_end_at, :presell_dispatch_on, :latest_presell_dispatch_on, :top_left_corner_tag_image,
            :show_expiration_date, :days_ahead_to_show_expiration, :is_seasonal, :is_fresh_daily, :expiration_reminder_before_n_days)
          optional :stock_keeping_units_attributes, type: Array do
            optional :all, using: API::Entities::StockKeepingUnit.documentation.except(:groups)
            optional :groups, type: Array do
              optional :id, type: Integer, desc: "产品或SKU ID"
              optional :type, type: String, values: ["MagicBean::Item", "MagicBean::StockKeepingUnit"], desc: "类型"
              optional :quantity, type: Integer, desc: "数量"
            end
          end
          optional :web_item_attributes, type: Hash do
            optional :all, using: API::Entities::StockKeepingUnit.documentation.dup.extract!(
              :id, :upper_images, :lower_images, :banner_images, :video)
          end
        end
        put do
          new_skus, edit_skus, destroy_skus, log_message, sku_errors = [], [], [], [], []

          # 只编辑SKU信息的话（参数只会有stock_keeping_units_attributes），则不需要设置product_attributes
          if current_store_id == resource.product.store_id && params[:title_zh_cn].present?
            set_product_params
            params[:product_attributes][:store_id] = resource.product.store_id
            params[:product_attributes][:id] ||= resource.product.id
          end

          (params["stock_keeping_units_attributes"] || []).each do |sku|
            if sku["_destroy"]
              destroy_skus << sku
            elsif sku["id"].present?
              edit_skus << sku
            else
              new_skus << sku
            end
          end

          new_title_zh_cn = params["title_zh_cn"]&.strip
          new_title_zh_tw = params["title_zh_tw"]&.strip
          new_title_en = params["title_en"]&.strip

          log_message << "商品标题（简中）从 #{resource.title_zh_cn} 改为 #{new_title_zh_cn}" if new_title_zh_cn.to_s != resource.title_zh_cn.to_s
          log_message << "商品标题（繁中）从 #{resource.title_zh_tw} 改为 #{new_title_zh_tw}" if new_title_zh_tw.to_s != resource.title_zh_tw.to_s
          log_message << "商品标题（英文）从 #{resource.title_en} 改为 #{new_title_en}" if new_title_en.to_s != resource.title_en.to_s

          if params["listing_type"] != resource.listing_type
            listing_type_message = "商品上架类型从 #{I18n.t("attributes.item/listing_types.#{resource.listing_type}")}更改为 #{I18n.t("attributes.item/listing_types.#{params["listing_type"]}")}"
            listing_type_message += ", 开卖时间为 #{params["start_selling_at"].in_time_zone}" if params["listing_type"] == "advance_on" && params["start_selling_at"].present?
            log_message << listing_type_message
          elsif params["listing_type"] == "advance_on" && params["start_selling_at"].present? && params["start_selling_at"] != resource.start_selling_at
            log_message << "商品开卖时间从 #{resource.start_selling_at} 更改为 #{params["start_selling_at"].in_time_zone}"
          end

          if params["is_presell"] != resource.is_presell
            presell_message = "商品预售状态从 #{resource.is_presell ? "是" : "否"} 更改为 #{params["is_presell"] ? "是" : "否"}"
            presell_message += ", 商品预售结束时间为 #{params["presell_end_at"].in_time_zone}, 预售可派送最早日期为 #{params["presell_dispatch_on"]}, 预售可派送最晚日期为 #{params["latest_presell_dispatch_on"]}" if params["is_presell"]
            log_message << presell_message
          elsif params["is_presell"]
            presell_messages = []
            presell_messages << "商品预售结束时间从 #{resource.presell_end_at} 更改为 #{params["presell_end_at"].in_time_zone}" if params["presell_end_at"] != resource.presell_end_at
            presell_messages << "预售可派送最早日期从 #{resource.presell_dispatch_on} 更改为 #{params["presell_dispatch_on"]}" if params["presell_dispatch_on"].to_s != resource.presell_dispatch_on.to_s
            presell_messages << "预售可派送最晚日期从 #{resource.latest_presell_dispatch_on} 更改为 #{params["latest_presell_dispatch_on"]}" if params["latest_presell_dispatch_on"].to_s != resource.latest_presell_dispatch_on.to_s
            log_message << presell_messages.join(", ") if presell_messages.present?
          end

          if destroy_skus.any?
            destroy_sku_ids = destroy_skus.pluck("id")

            has_bought_sku_ids = MagicBean::OrderItem.where(stock_keeping_unit_id: destroy_sku_ids).exists?
            response_error("删除的规格中不能包含被购买过的商品") if has_bought_sku_ids

            has_shopping_cart_sku_ids = MagicBean::ShoppingCartItem.where(stock_keeping_unit_id: destroy_sku_ids).exists?
            response_error("删除的规格中不能包含添加到购物车的商品") if has_shopping_cart_sku_ids

            has_gift_activity_sku_ids = MagicBean::GiftActivity.pluck(:rules).flatten.pluck("skus").flatten.pluck("sku_id") & destroy_sku_ids
            response_error("删除的规格中不能包含赠品活动中的商品") if has_gift_activity_sku_ids

            has_gift_sku_ids = MagicBean::Order.where.not(gifts_properties: nil).where("EXISTS (SELECT FROM json_array_elements(orders.gifts_properties) gift_element WHERE (gift_element->>'stock_keeping_unit_id')::int IN (?))", destroy_sku_ids).exists?
            response_error("删除的规格中不能包含赠品中的商品") if has_gift_sku_ids

            has_pool_gift_sku_ids = MagicBean::Order.where.not(pool_gifts_properties: nil).where("EXISTS (SELECT FROM json_array_elements(orders.pool_gifts_properties) gift_element WHERE (gift_element->>'stock_keeping_unit_id')::int IN (?))", destroy_sku_ids).exists?
            response_error("删除的规格中不能包含优惠池赠品中的商品") if has_pool_gift_sku_ids

            log_message << "删除SKU, 货号/规格为：#{destroy_skus.map { |sku| "#{sku["no"]}/#{sku["properties_text"]}" }.join(", ")}"
          end

          log_message << "新增SKU, 货号为：#{new_skus.map { |sku| "#{sku["no"]}" }.join(", ")}" if new_skus.present?

          edit_skus.each do |sku|
            old_sku = resource.stock_keeping_units.find(sku[:id])
            new_price_in_cent = sku["price_in_yuan"].present? ? (sku["price_in_yuan"].to_f * 100).round : nil
            new_user_price_in_cent = sku["new_user_price_in_yuan"].present? ? (sku["new_user_price_in_yuan"].to_f * 100).round : nil
            price_in_cent_changed = new_price_in_cent != old_sku&.price_in_cent
            new_user_price_in_cent_changed = new_user_price_in_cent != old_sku&.new_user_price_in_cent

            if price_in_cent_changed && current_admin_user.can_not_force_update_sku_price? && old_sku.price_less_than_supplier_cost_multiple?(new_price_in_cent)
              sku_errors << "规格【#{old_sku.properties_text}】售价需不低于进货价的指定倍数"
            end

            if new_user_price_in_cent_changed && current_admin_user.can_not_update_sku_new_user_price? && old_sku.new_user_price_less_than_supplier_cost_multiple?(new_user_price_in_cent)
              sku_errors << "规格【#{old_sku.properties_text}】新人价需不低于进货价的指定倍数"
            end

            new_discount_price_in_cent = sku["discount_price_in_yuan"].present? ? (sku["discount_price_in_yuan"].to_f * 100).round : nil
            new_barcode = sku["barcode"]&.split(",")&.map(&:strip)&.uniq&.join(",")

            log_message << "修改SKU（#{sku["no"]}/#{sku["properties_text"]}）价格: 从 #{old_sku.price_in_yuan} 改为 #{sku["price_in_yuan"]}" if (new_price_in_cent || 0) != old_sku.price_in_cent
            log_message << "修改SKU（#{sku["no"]}/#{sku["properties_text"]}）折扣价格: 从 #{old_sku.discount_price_in_yuan || "空"} 改为 #{sku["discount_price_in_yuan"].presence || "空"}" if new_discount_price_in_cent.to_i != old_sku.discount_price_in_cent.to_i
            if sku["quantity"] != old_sku.quantity
              log_message << "修改SKU（#{sku["no"]}/#{sku["properties_text"]}）数量: 从 #{old_sku.quantity} 改为 #{sku["quantity"]}"
              sku_errors << "商品 #{sku["no"]} 处于限时优惠期，不可修改库存" if old_sku.in_time_limited_promotion?
            end
            log_message << "修改SKU（#{sku["no"]}/#{sku["properties_text"]}）折扣数量: 从 #{old_sku.discount_quantity || "空"} 改为 #{sku["discount_quantity"].presence || "空"}" if sku["discount_quantity"].to_i != old_sku.discount_quantity.to_i
            log_message << "修改SKU（#{sku["no"]}/#{sku["properties_text"]}）barcode: 从 #{old_sku.barcode.presence || "空"} 改为 #{new_barcode.presence || "空"}" if new_barcode.to_s != old_sku.barcode.to_s
            log_message << "修改SKU（#{sku["no"]}/#{sku["properties_text"]}）是否特品: 从 #{old_sku.is_special ? "是" : "否"} 改为 #{sku["is_special"] ? "是" : "否"}" if sku["is_special"] != old_sku.is_special
            log_message << "修改SKU（#{sku["no"]}/#{sku["properties_text"]}）是否私厨: 从 #{old_sku.is_private_kitchen ? "是" : "否"} 改为 #{sku["is_private_kitchen"] ? "是" : "否"}" if sku["is_private_kitchen"] != old_sku.is_private_kitchen
            log_message << "修改SKU（#{sku["no"]}/#{sku["properties_text"]}）上架状态: 从 #{old_sku.on_sale ? "是" : "否"} 改为 #{sku["on_sale"] ? "是" : "否"}" if sku["on_sale"] != old_sku.on_sale
            log_message << "修改SKU（#{sku["no"]}/#{sku["properties_text"]}）营销模式: 从 #{I18n.t("activerecord.attributes.magic_bean/stock_keeping_unit/marketing_modes.#{old_sku.marketing_mode}")} 改为 #{I18n.t("activerecord.attributes.magic_bean/stock_keeping_unit/marketing_modes.#{sku["marketing_mode"]}")}" if sku["marketing_mode"] != old_sku.marketing_mode
          end

          if sku_errors.empty?
            authorize_and_update_resource({ log_message: log_message.join(", ") })
          else
            response_error(sku_errors.join("；"))
          end
        end

        desc "删除商品", {
          detail: <<-NOTES.strip_heredoc
            ```json
            {
              code: 200,
              message: "ok"
            }
            ```
          NOTES
        }
        delete do
          if resource.destroyable?
            standard_destroy(resource)
          else
            # 将软删除的产品的导入变化、sku货号/barcode加上后缀，避免新建SKU时货号重复
            resource.soft_delete!
            current_admin_user.operation_records.create(operatable: resource, content: "产品（no: #{resource.no}）软删除", store_id: current_store_id) 
            response_success
          end
        end

        desc "复制商品", {
          success: API::Entities::Item
        }
        post :copy do
          authorize! :create, resource_class

          item = resource.dup
          item.sales_count = 0
          item.likes_count = 0
          item.comments_count = 0
          item.stock_keeping_units << resource.stock_keeping_units.map do |v|
            v.dup.tap { |sku| sku.comments_count = 0 }
          end
          standard_save item, API::Entities::Item
        end

        desc "手动统一商品与 SKU 的库存和售价", {
          success: API::Entities::Item
        }
        post :sync_sku_attrs do
          if resource.ae_drop_shipper
            raise CanCan::AccessDenied unless current_user.permissions.include?("ae_items")
          else
            authorize! :update, resource
          end

          resource.sync_sku_attrs

          response_resource
        end

        desc "获取WMS库存"
        get :wms_stock do
          resource.get_skus_wms_stock
        end

        namespace :comments, desc: "评论列表" do
          desc "评论列表", {
            success: API::Entities::Comment,
            is_array: true
          }
          params do
            use :created_at_search
          end
          paginate
          get do
            present paginate(resource.comments.ransack(ransack_params).result.order(created_at: :desc).includes(:user)), with: API::Entities::Comment
          end
        end

        namespace :item_nutrition_values, desc: "成分表" do
          desc "成分表", {
            success: API::Entities::ItemNutritionValue,
            is_array: true
          }
          get do
            item = MagicBean::Item.includes(item_nutrition_values: { nutrition: :translations }).find(params[:id])
            if item.ae_drop_shipper
              raise CanCan::AccessDenied unless current_user.permissions.include?("ae_items")
            else
              authorize! :read, item
            end
            present item.item_nutrition_values, with: API::Entities::ItemNutritionValue
          end
        end
      end
    end
  end
end
