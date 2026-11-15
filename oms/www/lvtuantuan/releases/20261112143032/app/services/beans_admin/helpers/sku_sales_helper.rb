# frozen_string_literal: true

module BeansAdmin::Helpers
  module SkuSalesHelper
    include ::BeansAdmin::Helpers::OrderChannelPermissionHelper

    # 如果admin_user不传，则默认计算所有平台订单数据
    def sales_collections(params, order_by, store_id, admin_user = nil)
      item_category_parent_id = params["catetory_ids"].try(:[], 0)
      item_category_id = params["catetory_ids"].try(:[], 1)
      item_parent_category_id_in = set_item_parent_category_id_in(params, item_category_parent_id)

      # https://bugs.ruby-lang.org/issues/12961

      # 商品还是默认全部时间段，订单默认当天
      sku_created_at_range = ((params["created_at_gteq"]&.to_datetime || DateTime.new(2019)).in_time_zone.beginning_of_day)..(params["created_at_lteq"]&.to_datetime&.in_time_zone&.end_of_day || Time.current)
      
      reset_order_created_at_condition(params)

      order_created_at_range = time_range(params["order_created_at_gteq"], params["order_created_at_lteq"])

      delivery_type_array = params["order_delivery_type_in"].present? ? params["order_delivery_type_in"] : MagicBean::Order.delivery_types.values

      # 只查询有销量的sku
      # explain发现嵌套到order_items的查询很费时，所以这里先查出order_ids，再查sku_ids，这里需要部署后观察性能，看看是否有内存风险
      order_ids = MagicBean::Order.paid.where(delivery_type: delivery_type_array, created_at: order_created_at_range, channel: order_channel_permission_values(admin_user, params["order_channels"])).ransack({ store_id_eq: store_id, delivery_date_gteq: params["order_delivery_date_gteq"], delivery_date_lteq: params["order_delivery_date_lteq"] }).result.distinct.pluck(:id)
      sku_ids = MagicBean::OrderItem.where(order_id: order_ids).distinct.pluck(:stock_keeping_unit_id)

      # 需要把shopline有销量的SKU也展示处理
      sku_nos = MagicBean::ThirdPartyOrder.shopline.where(created_at: order_created_at_range, delivery_type: delivery_type_array - ["virtual_delivery"], store_id: store_id).ransack({ delivery_date_gteq: params["order_delivery_date_gteq"], delivery_date_lteq: params["order_delivery_date_lteq"] }).result.map(&:order_items).flatten.map {|order_item| order_item["sku"]}.uniq
      sku_ids = (sku_ids + MagicBean::StockKeepingUnit.where(store_id: store_id, no: sku_nos).ids).uniq
      
      if order_ids.present?
        left_joins_sql = "LEFT OUTER JOIN order_items ON order_items.stock_keeping_unit_id = stock_keeping_units.id AND order_items.order_id in (#{order_ids.join(",")})"
        @collection = MagicBean::StockKeepingUnit.where(id: sku_ids)
                        .includes(:newest_supplier, item: [:translations, category: :translations, parent_category: :translations])
                        .joins(left_joins_sql)
                        .select("stock_keeping_units.*, COALESCE(SUM(order_items.quantity), 0) AS sales_count, COALESCE(SUM(order_items.amount_in_cent) / 100.0, 0) AS sum_original_amount_in_yuan, COALESCE(SUM(order_items.real_price_in_cent * order_items.quantity) / 100.0, 0) AS sum_price_in_yuan")
                        .where(created_at: sku_created_at_range)
                        .ransack({ store_id_eq: store_id, id_in: target_supplier_ids(params["supplier_name_cont"]), no_or_barcode_cont: params["no_or_barcode_cont"], item_id_in: target_item_ids(params["custom_list_id"]), shoppingunit_cont: params["shoppingunit_cont"], item_ae_drop_shipper_eq: params["ae_drop_shipper"] }).result
                        .reorder(Arel.sql(order_by))
                        .group("stock_keeping_units.id")
      else
        @collection = MagicBean::StockKeepingUnit.none
      end

      @collection = @collection.where("items.translated_searchable_title ILIKE ?", "%#{params["item_title_cont"]}%") if params["item_title_cont"].present?

      # 经测试，如果把分类条件放到sku的ransack中，会导致查询速度变慢，所以这里单独查询item
      if item_parent_category_id_in.present?
        item_ids = MagicBean::Item.ransack({ store_id_eq: store_id, parent_category_id_in: item_parent_category_id_in, category_id_eq: item_category_id }).result.pluck(:id)
        @collection = @collection.where(item_id: item_ids)
      end
    end

    def shopline_sku_sales_collections(params, store_id, admin_user = nil)
      return {} if params["order_channels"].present? && params["order_channels"].exclude?("shopline")

      reset_order_created_at_condition(params)

      order_created_at_range = time_range(params["order_created_at_gteq"], params["order_created_at_lteq"])
      delivery_type_array = params["order_delivery_type_in"].present? ? params["order_delivery_type_in"] : MagicBean::ThirdPartyOrder.delivery_types.values

      # 第三方订单无法直接拿到sku的ID，所以这里格式化成{ "#{sku_id}-#{store_id}": { sales_count: 0, sales_amount: 0, redund_count: 0, redund_amount: 0 } }
      sale_and_refund_hash = {}

      MagicBean::ThirdPartyOrder.shopline.where(created_at: order_created_at_range, delivery_type: delivery_type_array - ["virtual_delivery"], store_id: store_id).ransack({ delivery_date_gteq: params["order_delivery_date_gteq"], delivery_date_lteq: params["order_delivery_date_lteq"] }).result.each do |order|
        order.order_items.each do |order_item|
          # 如果sku为空，则跳过
          next if order_item["sku"].blank?

          sale_and_refund_hash["#{order_item["sku"]}-#{order.store_id}"] ||= { sales_count: 0, sales_amount: 0, redund_count: 0, redund_amount: 0 }
          sale_and_refund_hash["#{order_item["sku"]}-#{order.store_id}"][:sales_count] += order_item["quantity"]
          sale_and_refund_hash["#{order_item["sku"]}-#{order.store_id}"][:sales_amount] = (sale_and_refund_hash["#{order_item["sku"]}-#{order.store_id}"][:sales_amount] + order_item["price"].to_f * order_item["quantity"]).round(2)
        end

        if order.refunds.present?
          order.refunds.each do |refund|
            refund["refund_line_items"].each do |item|
              # 如果sku为空，则跳过
              next if item["line_item"]["sku"].blank?

              sale_and_refund_hash["#{item["line_item"]["sku"]}-#{order.store_id}"][:redund_count] += item["quantity"]
              sale_and_refund_hash["#{item["line_item"]["sku"]}-#{order.store_id}"][:redund_amount] = (sale_and_refund_hash["#{item["line_item"]["sku"]}-#{order.store_id}"][:redund_amount] + item["subtotal"].to_f).round(2)
            end
          end
        end
      end

      sale_and_refund_hash
    end

    # 商品销量也要退款商品数量、退款金额，所以这里要进行计算
    # sku_ids传[]则获取全部
    # 如果admin_user不传，则默认计算所有平台订单数据
    def sales_collections_returns_data(sku_ids, params, admin_user = nil)
      reset_order_created_at_condition(params)

      order_created_at_range = time_range(params["order_created_at_gteq"], params["order_created_at_lteq"])

      # 售后同意时间范围 = 发货日期范围 || 订单创建时间范围
      after_sale_agreed_at_range =
        if params["order_delivery_date_gteq"] || params["order_delivery_date_lteq"]
          time_range(params["order_delivery_date_gteq"], params["order_delivery_date_lteq"])
        else
          order_created_at_range
        end
      sku_return_hash = {}

      # 需要根据用户权限，过滤掉平台订单的售后
      MagicBean::StockKeepingUnit.left_joins({ order_items: [:after_sales] })
        .select("stock_keeping_units.id, COALESCE(SUM(after_sales_order_items.quantity), 0) AS sum_after_sale_quantity, COALESCE(SUM(after_sales_order_items.real_amount_in_cent) / 100.0, 0) AS sum_after_sale_in_yuan")
        .where(after_sales: { id: MagicBean::AfterSale.where(status: [:wait_buyer_return_goods, :wait_seller_confirm_goods, :refunding, :finished], agreed_at: after_sale_agreed_at_range).ransack({ order_channel_in: order_channel_permission_values(admin_user, params["order_channels"]) }).result.select(:id) })
        .ransack({ id_in: sku_ids, item_ae_drop_shipper_eq: params["ae_drop_shipper"] }).result.group("stock_keeping_units.id").each do |sku|
        sku_return_hash["#{sku.id}"] = { sum_after_sale_quantity: sku.sum_after_sale_quantity, sum_after_sale_in_yuan: sku.sum_after_sale_in_yuan }
      end
      sku_return_hash
    end

    def sales_plan_collections(params, order_by, store_id)
      item_category_parent_id = params["catetory_ids"].try(:[], 0)
      item_category_id = params["catetory_ids"].try(:[], 1)
      item_parent_category_id_in = set_item_parent_category_id_in(params, item_category_parent_id)

      # https://bugs.ruby-lang.org/issues/12961

      order_created_at_start_time, order_created_at_end_time = time_range_processor(
        params["order_created_at_gteq"],
        params["order_created_at_lteq"]
      )
      order_created_at_range = order_created_at_start_time..order_created_at_end_time
      days = (order_created_at_end_time.to_date - order_created_at_start_time.to_date)

      sql_sentence = <<-SQL
        stock_keeping_units.*, COALESCE(SUM(order_items.quantity), 0) AS sales_count
      SQL

      left_joins_sql = "LEFT OUTER JOIN order_items ON order_items.stock_keeping_unit_id = stock_keeping_units.id AND order_items.order_id in (#{MagicBean::Order.select(:id).paid.where(created_at: order_created_at_range).to_sql})"

      @collection = MagicBean::StockKeepingUnit
                      .includes(:newest_supplier, :wms_inventories, item: [:brand, category: :translations, parent_category: :translations])
                      .joins(left_joins_sql)
                      .select(sql_sentence)
                      .ransack({ store_id_eq: store_id, id_in: target_supplier_ids(params["supplier_name_cont"]), no_or_barcode_cont: params["no_or_barcode_cont"],
                        gmv_sku_level_eq: params["gmv_sku_level_eq"], gp_sku_level_eq: params["gp_sku_level_eq"], is_special_eq: params["is_special_eq"], on_sale_eq: params["on_sale_eq"], shoppingunit_cont: params["shoppingunit_cont"],
                        item_ae_drop_shipper_eq: params["ae_drop_shipper"] }).result
                      .reorder(Arel.sql(order_by))
                      .group("stock_keeping_units.id")

      @collection = @collection.where("items.translated_searchable_title ILIKE ?", "%#{params["item_title_cont"]}%") if params["item_title_cont"].present?

      if item_parent_category_id_in.present?
        item_ids = MagicBean::Item.ransack({ store_id_eq: store_id, parent_category_id_in: item_parent_category_id_in, category_id_eq: item_category_id }).result.pluck(:id)
        @collection = @collection.where(item_id: item_ids)
      end
    end

    # 获取时间段内的sku有效库存日期数量
    def sales_plan_sku_valid_inventory_dates_hash(params, store_id)
      start_time, end_time = time_range_processor(
        params["order_created_at_gteq"],
        params["order_created_at_lteq"]
      )
      MagicBean::SkuValidInventoryDate.where(store_id: store_id, date: start_time.to_date..end_time.to_date).group(:stock_keeping_unit_id).distinct.count(:date)
    end
    
    def sku_reserved_quantity_hash(store_id)
      promotion_skus_hash = {}
      MagicBean::TimeLimitedPromotion.includes(:time_limited_promotion_prices).active.where(store_id: store_id).each do |promotion|
        promotion.time_limited_promotion_prices.each do |promotion_price|
          promotion_skus_hash[promotion_price.stock_keeping_unit_id] = promotion_price.reserved_quantity.to_i
        end
      end
      promotion_skus_hash
    end

    def sales_supplier_collections(params, order_by, store_id)
      item_category_parent_id = params["catetory_ids"].try(:[], 0)
      item_category_id = params["catetory_ids"].try(:[], 1)
      item_parent_category_id_in = set_item_parent_category_id_in(params, item_category_parent_id)

      sku_created_at_range = ((params["created_at_gteq"]&.to_datetime || DateTime.new(2019)).in_time_zone.beginning_of_day)..(params["created_at_lteq"]&.to_datetime&.in_time_zone&.end_of_day || DateTime::Infinity.new)

      @collection = MagicBean::StockKeepingUnit
                      .includes([:newest_supplier, item: [category: :translations, parent_category: :translations]])
                      .select("stock_keeping_units.*")
                      .where(created_at: sku_created_at_range)
                      .ransack({ store_id_eq: store_id, id_in: target_supplier_ids(params["newest_supplier_name_cont"]), barcode_or_no_cont: params["barcode_or_no_cont"],
                        item_ae_drop_shipper_eq: params["ae_drop_shipper"] }).result
                      .reorder(Arel.sql(order_by))
                      .group("stock_keeping_units.id")

      @collection = @collection.where("items.translated_searchable_title ILIKE ?", "%#{params["item_title_cont"]}%") if params["item_title_cont"].present?
      
      if item_parent_category_id_in.present?
        item_ids = MagicBean::Item.ransack({ store_id_eq: store_id, parent_category_id_in: item_parent_category_id_in, category_id_eq: item_category_id }).result.pluck(:id)
        @collection = @collection.where(item_id: item_ids)
      end
    end

    def sku_returns_collection(params, order_by, store_id, admin_user = nil)
      # https://bugs.ruby-lang.org/issues/12961
      sku_created_at_range = ((params["created_at_gteq"]&.to_datetime || DateTime.new(2019)).in_time_zone.beginning_of_day)..(params["created_at_lteq"]&.to_datetime&.in_time_zone&.end_of_day || DateTime::Infinity.new)

      # 需求改为查同意售后时间
      after_sale_agreed_at_range = time_range(params["after_sale_agreed_at_gteq"], params["after_sale_agreed_at_lteq"])

      item_category_parent_id = params["catetory_ids"].try(:[], 0)
      item_category_id = params["catetory_ids"].try(:[], 1)
      item_parent_category_id_in = set_item_parent_category_id_in(params, item_category_parent_id)

      @collection = MagicBean::StockKeepingUnit
                      .includes(:newest_supplier, item: [category: :translations, parent_category: :translations])
                      .left_joins({ item: :category }, { order_items: [:after_sales] })
                      .select("stock_keeping_units.*, COALESCE(SUM(after_sales_order_items.quantity), 0) AS sum_after_sale_quantity, COALESCE(SUM(after_sales_order_items.real_amount_in_cent) / 100.0, 0) AS sum_after_sale_in_yuan")
                      .where(created_at: sku_created_at_range)
                      .where(after_sales: { id: MagicBean::AfterSale.where(status: [:wait_buyer_return_goods, :wait_seller_confirm_goods, :refunding, :finished], agreed_at: after_sale_agreed_at_range).ransack({ order_channel_in: order_channel_permission_values(admin_user, params["order_channels"]) }).result.select(:id) })
                      .ransack({ store_id_eq: store_id, id_in: target_supplier_ids(params["supplier_name_cont"]), no_or_barcode_cont: params["no_or_barcode_cont"], item_ae_drop_shipper_eq: params["ae_drop_shipper"] }).result
                      .reorder(Arel.sql(order_by))
                      .group("stock_keeping_units.id")      

      @collection = @collection.where("items.translated_searchable_title ILIKE ?", "%#{params["item_title_cont"]}%") if params["item_title_cont"].present?

      if item_parent_category_id_in.present?
        item_ids = MagicBean::Item.ransack({ store_id_eq: store_id, parent_category_id_in: item_parent_category_id_in, category_id_eq: item_category_id }).result.pluck(:id)
        @collection = @collection.where(item_id: item_ids)
      end
    end

    # 目前只给计划销量用
    def time_range_processor(start_date, end_date)
      [
        (start_date&.to_datetime || (Date.current - 31.days)&.beginning_of_day),
        (end_date&.to_datetime&.in_time_zone&.end_of_day || Date.current.beginning_of_day)
      ]
    end

    def target_supplier_ids(supplier_name_cont)
      if supplier_name_cont.present?
        MagicBean::Supplier.where(id: MagicBean::Supplier.select("DISTINCT ON (stock_keeping_unit_id) id").order("stock_keeping_unit_id, updated_at DESC")).ransack({ name_cont: supplier_name_cont }).result.pluck(:stock_keeping_unit_id) + [-1]
      else
        []
      end
    end

    def target_item_ids(custom_list_id)
      if custom_list_id
        custom_list = MagicBean::CustomList.find custom_list_id
        custom_list.custom_list_items.pluck(:item_id).uniq + [-1]
      else
        []
      end
    rescue
      # 乱传custom_list_id认为是没传
      []
    end

    def set_item_parent_category_id_in(params, category_parent_id)
      if params["item_parent_category_id_in"].present? && category_parent_id.present?
        (params["item_parent_category_id_in"] & [category_parent_id.to_i]) + [-1]
      elsif category_parent_id.present?
        [category_parent_id]
      else
        params["item_parent_category_id_in"]
      end
    end

    def order_channel_permission_values(admin_user, order_channels_filter)
      channels = admin_user ? calculate_order_channel_permissions(admin_user) : MagicBean::Order.channels.keys
      channels = order_channels_filter.blank? ? channels : (channels & order_channels_filter)
      # 当过滤条件为shopline时，返回-1
      channels.blank? && order_channels_filter.include?("shopline") ? [-1] : channels
    end

    # 如果没传查询日期，只查当天数据
    def time_range(start_time, end_time)
      start_time = start_time&.to_datetime&.in_time_zone&.beginning_of_day
      end_time = end_time&.to_datetime&.in_time_zone&.end_of_day

      if start_time.present? && end_time.present?
        start_time..end_time
      elsif start_time.present?
        start_time..start_time.end_of_day
      elsif end_time.present?
        end_time.beginning_of_day..end_time
      else
        Time.current.beginning_of_day..Time.current.end_of_day
      end
    end

    # 如果只选了发货时间，需要重置下单时间，不然下单时间只会查今天的数据，影响最终查询
    def reset_order_created_at_condition(params)
      if (params["order_delivery_date_gteq"].present? || params["order_delivery_date_lteq"].present?) && params["order_created_at_gteq"].blank? && params["order_created_at_lteq"].blank?
        params["order_created_at_gteq"] = "2019-01-01"
        params["order_created_at_lteq"] = Date.current.to_s
      end
    end
  end
end
