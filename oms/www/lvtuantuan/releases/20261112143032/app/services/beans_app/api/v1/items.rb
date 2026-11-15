# frozen_string_literal: true

module BeansApp
  class API::V1::Items < ::API
    helpers ::ApiHelpers::HistoryHelper
    helpers ::ApiHelpers::ItemHelper

    helpers do
      def end_of_association_chain
        MagicBean::Item.on_sale
      end

      def resource
        @resource ||= MagicBean::Item.find_by!("#{find_by_key}" => params[find_by_key])

        # 如果当前用户定位不在该商品的store内，则查找用户store内是否有该商品
        @resource = @resource.product.items.find_by(store_id: current_store_id) || @resource if @resource.store_id != current_store_id

        @resource
      end

      def includes
        [:on_sale_skus, :parent_category, :parent_web_category, :translations, brand: :translations, category: :translations]
      end

      def default_order
        ["position ASC", "created_at DESC"]
      end

      def set_category_ransack_params
        # 处理思路：保持 API 原有的分类入参 key 不变，根据请求 channel 是 app/mini_program 或 web 分别设置 category 或 web_category 查询条件

        # 如果同时传了 category_id_eq 和 category_parent_id_eq ，则删除 category_parent_id_eq ，因为涉及到次级分类的查询，两个条件会影响搜索结果
        category_params = {}
        params.delete(:category_parent_id_eq) if params[:category_id_eq].present? && params[:category_parent_id_eq].present?

        if params[:category_id_eq].present?
          if ebest_channel == "web"
            params[:minor_web_category_id_or_web_category_id_eq] = params[:category_id_eq]
            category_params[:minor_or_web_category_id] = [params[:category_id_eq]]
          else
            params[:minor_category_id_or_category_id_eq] = params[:category_id_eq]
            category_params[:minor_or_category_id] = [params[:category_id_eq]]
          end

          params.delete(:category_id_eq)
        end

        if params[:category_id_in].present?
          if ebest_channel == "web"
            params[:minor_web_category_id_or_web_category_id_in] = params[:category_id_in]
            category_params[:minor_or_web_category_id] = category_params[:minor_or_web_category_id].present? ? (category_params[:minor_or_web_category_id] & params[:category_id_in]) : params[:category_id_in]
          else
            params[:minor_category_id_or_category_id_in] = params[:category_id_in]
            category_params[:minor_or_category_id] = category_params[:minor_or_category_id].present? ? (category_params[:minor_or_category_id] & params[:category_id_in]) : params[:category_id_in]
          end

          params.delete(:category_id_in)
        end

        if params[:category_parent_id_in].present?
          if ebest_channel == "web"
            params[:minor_web_category_parent_id_or_web_category_parent_id_in] = params[:category_parent_id_in]
            category_params[:minor_or_web_category_parent_id] = params[:category_parent_id_in]
          else
            params[:minor_category_parent_id_or_category_parent_id_in] = params[:category_parent_id_in]
            category_params[:minor_or_category_parent_id] = params[:category_parent_id_in]
          end

          params.delete(:category_parent_id_in)
        end

        if params[:category_parent_id_eq].present?
          if ebest_channel == "web"
            params[:minor_web_category_parent_id_or_web_category_parent_id_eq] = params[:category_parent_id_eq]
            category_params[:minor_or_web_category_parent_id] = if category_params[:minor_or_web_category_parent_id].present?
              category_params[:minor_or_web_category_parent_id] & [params[:category_parent_id_eq]]
            else
              [params[:category_parent_id_eq]]
            end
            # 如果只传了一级分类，需要把隐藏的二级分类对应的商品过滤掉（只隐藏主分类的子分类的商品）
            parent_category = MagicBean::WebCategory.find_by(id: params[:category_parent_id_eq])
            if parent_category
              children_ids = parent_category.children.hidden.ids
              if children_ids.present?
                params[:web_category_id_not_in] = children_ids 
                category_params[:web_category_id_not_in] = children_ids
              end
            end
          else
            params[:minor_category_parent_id_or_category_parent_id_eq] = params[:category_parent_id_eq]
            category_params[:minor_or_category_parent_id] = if category_params[:minor_or_category_parent_id].present?
              category_params[:minor_or_category_parent_id] & [params[:category_parent_id_eq]]
            else
              [params[:category_parent_id_eq]]
            end
            # 如果只传了一级分类，需要把隐藏的二级分类对应的商品过滤掉（只隐藏主分类的子分类的商品）
            parent_category = MagicBean::Category.find_by(id: params[:category_parent_id_eq])
            if parent_category
              children_ids = parent_category.children.hidden.ids
              if children_ids.present?
                params[:category_id_not_in] = children_ids
                category_params[:category_id_not_in] = children_ids
              end
            end
          end

          params.delete(:category_parent_id_eq)
        end

        category_params
      end
    end

    namespace :items, desc: "产品API" do

      include Grape::Kaminari

      desc "产品列表", {
        success: API::Entities::SimpleItem,
        is_array: true,
        action_type: "searched",
        page_type: "item",
        skip_authentication: true
      }
      paginate
      params do
        optional :order_by, type: String
        optional :keyword, types: [String, Array], desc: "搜索商品标题、描述，多个关键字用空格分割", coerce_with: ->(val) { val.to_s.split(" ") }
        optional :original_keyword, types: [String, Array], desc: "原始搜索关键字，用于记录", coerce_with: ->(val) { val.to_s.split(" ") }
        optional :category_id_eq, type: Integer, desc: "产品分类ID"
        optional :category_id_in, type: Array[Integer], coerce_with: ->(val) { val.to_s.split(",").map(&:to_i) }, desc: "产品二级分类 ids"
        optional :category_parent_id_in, type: Array[Integer], coerce_with: ->(val) { val.to_s.split(",").map(&:to_i) }, desc: "产品一级分类ids"
        optional :category_parent_id_eq, type: Integer, desc: "一级分类ID"
        optional :id_in, types: Array[Integer], desc: "ids", coerce_with: ->(v) { v.to_s.split(",").map(&:to_i) }, documentation: { param_type: "query" }
        optional :delivery_area_id, type: Integer, desc: "送货上门区域 Id"
        optional :custom_lists_id_eq, type: Integer, desc: "自定义列表 Id"
        optional :brand_id_in, type: Array[Integer], coerce_with: ->(val) { val.split(",").map(&:to_i) }, desc: "品牌ids"
        optional :storage_method_in, type: Array[String], values: -> { MagicBean::Item.storage_methods.keys }, desc: "存储方式：room_temp_storage: 常温，refrigerated_storage: 冷藏，frozen_storage: 冷冻"
        optional :delivery_type, types: Array, values: -> { MagicBean::Item::DELIVERY_TYPE_ARRAY }, desc: "配送类型：merchant_delivery: 配送，express: 邮寄，self_pick: 自提"
        optional :price_in_cent_gteq, type: Integer, coerce_with: ->(val) { val.blank? ? nil : (val.to_f * 100).to_i }, desc: "价格区间最低价（传入值货币为元，例如：1.60）"
        optional :price_in_cent_lteq, type: Integer, coerce_with: ->(val) { val.blank? ? nil : (val.to_f * 100).to_i }, desc: "价格区间最高价（传入值货币为元，例如：10.60）"
        optional :in_stock_only, type: Grape::API::Boolean, desc: "true 为仅看有货"
        optional :new_arrival, type: Grape::API::Boolean, desc: "true 为新品（即创建一个月内的商品）"
        optional :special_offer, type: Grape::API::Boolean, desc: "true 为特价商品（即售价低于划线价的商品）"
        optional :free_shipping_eq, type: Grape::API::Boolean, desc: "true 为参与包邮"
        optional :freight_type_eq, type: String, values: -> { MagicBean::Item.freight_types.keys }, desc: "参与包邮要传freight_template"
        optional :item_type_eq, type: String, values: -> { MagicBean::Item.item_types.keys }, desc: "当日达商品才需要传"
        optional :ae_drop_shipper_eq, type: Grape::API::Boolean, desc: "true 为跨境购商品"
        optional :item_tag_id_eq, type: Integer, desc: "商品标签id"
      end
      get do
        custom_lists_id_eq = params[:custom_lists_id_eq]
        custom_list = MagicBean::CustomList.find(custom_lists_id_eq) if custom_lists_id_eq.present?
        search_category_params = set_category_ransack_params

        # ES搜索的话，就无需过滤掉赠品
        # TODO: ES搜索暂不处理标签逻辑、新品新逻辑、区分跨境购
        if MagicBean::Item.es_connected?
          # 自定义列表需要根据设置的排序来显示，所以沿用原来的逻辑
          if params[:keyword].blank? && custom_lists_id_eq.present? && params[:order_by].blank? && custom_list.normal?
            @collection = MagicBean::Item.includes(includes).on_sale_with_stock.send("#{ebest_channel}_channel")
            params[:store_id_eq] = current_store_id
            params[:quantity_gt] = 0 if params[:in_stock_only]
            # 新品：开卖时间在一个月内的产品
            params[:first_sale_at_gteq] = 1.month.ago.beginning_of_day if params[:new_arrival]
            @collection = @collection.not_merchant_delivery unless current_delivery_area
            @collection = @collection.delivery_type_contains_any(params[:delivery_type]) if params[:delivery_type].present?
            @collection = @collection.special_offer if params[:special_offer]
            @collection = @collection.accessible_by(current_ability).ransack(ransack_params).result.reorder(MagicBean::CustomList.item_default_order).page(params[:page].to_i).per(params[:per_page].to_i).padding(params[:offset].to_i)
            
            # 用@collection.map(&:id)会导致在查询最后一页时，total_count不正确，所以这里用pluck
            @groupon_activities = MagicBean::GrouponActivity.published.going.where(item_id: @collection.pluck(:id))
          else
            if params[:keyword].present?
              keyword = params[:keyword].join(" ")
              save_item_search_history_to_redis
            else
              keyword = "*"
            end

            search_params = { keyword: keyword, store_id: current_store_id, channel: ebest_channel, includes: includes }.merge(search_category_params)
            in_stock_only = params[:in_stock_only]
            search_params[:delivery_types] = search_delivery_types
            search_params[:delivery_types] = search_params[:delivery_types] & params[:delivery_type] if params[:delivery_type].present?
            search_params[:first_sale_at_gteq] = 1.month.ago.beginning_of_day if params[:new_arrival]
            search_params[:special_offer] = true if params[:special_offer]
            search_params[:id_in] = params[:id_in] if params[:id_in].present?
            search_params[:brand_id_in] = params[:brand_id_in] if params[:brand_id_in].present?
            search_params[:item_type_eq] = params[:item_type_eq] if params[:item_type_eq].present?
            search_params[:freight_type_eq] = params[:freight_type_eq] if params[:freight_type_eq].present?
            search_params[:storage_method_in] = params[:storage_method_in] if params[:storage_method_in].present?
            search_params[:price_in_cent_gteq] = params[:price_in_cent_gteq] if params[:price_in_cent_gteq].present?
            search_params[:price_in_cent_lteq] = params[:price_in_cent_lteq] if params[:price_in_cent_lteq].present?
            # TODO: 后续如果继续用ES，这里需要把ae_drop_shipper_eq加到search_params

            if custom_lists_id_eq.present?
              in_stock_only = true

              if custom_list.normal?
                search_params[:custom_list_id] = custom_lists_id_eq
              elsif custom_list.guess_you_like?
                sort_item_ids = guess_you_like_item_ids
                search_params[:sort_item_ids] = sort_item_ids
              elsif custom_list.new_product?
                search_params[:first_sale_at_gteq] = 1.month.ago.beginning_of_day
                search_params[:new_product_custom_list] = true

                # 如果custom_list为新品，且作为二级分类，需要过加上一级分类过滤条件
                search_params[:minor_or_category_parent_id] = custom_list.parent_category_id if custom_list.as_category && custom_list.parent_category_id?
              end
            end

            # in_stock_only为false时不传in_stock
            search_params[:in_stock] = true if in_stock_only
            search_params[:free_shipping] = true if params[:free_shipping_eq]

            if params[:order_by].present?
              search_params[:order_by] = (params[:order_by].gsub("sales_count", "display_sales_count").split(",").map(&:strip).compact + default_order).uniq
            end

            @collection = MagicBean::Item.es_search(search_params, params[:page] || 1, params[:per_page] || 25, params[:offset].to_i)

            # ES查询select会报错，还是得用map
            @groupon_activities = MagicBean::GrouponActivity.published.going.where(item_id: @collection.map(&:id))
          end

          present custom_paginate(@collection), with: API::Entities::SimpleItem, groupon_activities: @groupon_activities, is_new_user: is_new_user, like_item_ids: like_item_ids, active_top_left_item_hash: active_top_left_item_hash,
            exclusive_coupon_item_info: exclusive_coupon_item_info, buy_n_discount_item_info: buy_n_discount_item_info, preferential_pool_item_infos: preferential_pool_item_infos, allow_view_same_tag_items_info: allow_view_same_tag_items_info
        else
          # 普通搜索列表过滤掉赠品
          @collection = if custom_lists_id_eq.present?
            if custom_list.guess_you_like?
              params.delete(:custom_lists_id_eq)
              item_ids = guess_you_like_item_ids

              MagicBean::Item.includes(:translations, brand: :translations).on_sale_with_stock.not_gift.send("#{ebest_channel}_channel").where(id: item_ids).reorder_by_ids(item_ids)
            elsif custom_list.new_product?
              params[:minor_category_parent_id_or_category_parent_id_eq] = custom_list.parent_category_id if custom_list.as_category && custom_list.parent_category_id?
              # TODO: 新品自定义列表需要根据first_sale_at排序，删除position排序，该接口都是用ES搜索，非ES搜索要改挺复杂，先不改
              params[:g] = MagicBean::Item.new_product_ransack_params
              params.delete(:custom_lists_id_eq)
              params[:ae_drop_shipper_eq] = custom_list.ae_drop_shipper
              # 新品无库存的也要展示
              MagicBean::Item.includes(:translations, brand: :translations).on_sale.not_gift.send("#{ebest_channel}_channel")
            else
              MagicBean::Item.includes(:translations, brand: :translations).on_sale_with_stock.not_gift.send("#{ebest_channel}_channel")
            end
          else
            MagicBean::Item.includes(:translations, brand: :translations).on_sale.not_gift.send("#{ebest_channel}_channel")
          end

          params[:store_id_eq] = current_store_id
          params[:quantity_gt] = 0 if params[:in_stock_only]
          params[:item_tag_relations_item_tag_id_eq] = params[:item_tag_id_eq] if params[:item_tag_id_eq].present?
          params[:g] = MagicBean::Item.new_product_ransack_params if params[:new_arrival]

          @collection = @collection.not_merchant_delivery unless current_delivery_area
          @collection = @collection.delivery_type_contains_any(params[:delivery_type]) if params[:delivery_type].present?
          @collection = @collection.special_offer if params[:special_offer]
          @collection = @collection.accessible_by(current_ability).includes(includes).ransack(ransack_params)

          if params[:order_by].present?
            order_by = (params[:order_by].gsub("sales_count", "display_sales_count").split(",").map(&:strip).compact + default_order).uniq
            @collection.sorts = order_by
          end

          @collection = if params[:keyword].present?
            save_item_search_history_to_redis
            category_text = ebest_channel == "web" ? "web_category" : "category"
            like_sql = MagicBean::Item.unscoped.ransack({ "translated_searchable_title_or_translated_searchable_description_or_#{category_text}_search_keywords_cont_any": params[:keyword] }).result.to_sql.split("WHERE ").last
            tag_like_sql = MagicBean::Item.unscoped.tagged_with(params[:keyword], any: true).to_sql.gsub("SELECT \"items\".* FROM \"items\" WHERE ", "")

            @collection = @collection.result.select("items.*")
            if params[:order_by].blank?
              order_sqls = like_sql.split(") OR (")
              # 标题多次匹配中要多次计分，所以重组sql
              # 关键词包含单引号会导致查询报错，这里要处理单引号
              title_score_sql = params[:keyword].map { |k| "CASE WHEN items.translated_searchable_title ILIKE '%#{k&.gsub("'", "''")}%' THEN 9 ELSE 0 END" }.join(' + ')
              description_order_sql = order_sqls[1].gsub(")", "")
              category_like_sql = order_sqls[2].gsub(")", "")

              # 计算匹配中标题、标签、分类关键字、描述的分数
              match_score_sql = "(#{title_score_sql} + CASE WHEN #{tag_like_sql} THEN 4 ELSE 0 END + CASE WHEN #{category_like_sql} THEN 2 ELSE 0 END + CASE WHEN #{description_order_sql} THEN 1 ELSE 0 END) AS score"

              # 排序：正常商品 - 即将上架商品 - 缺货商品
              @collection.left_joins(category_text.to_sym).select(match_score_sql).where("(#{like_sql} or #{tag_like_sql})")
                .reorder("CASE WHEN items.quantity = 0 THEN 7 WHEN items.listing_type = 2 and items.start_selling_at > '#{Time.current}' THEN 6 ELSE 5 END, score desc, items.position ASC, items.created_at DESC")
            else
              @collection.left_joins(category_text.to_sym).where("(#{like_sql} or #{tag_like_sql})").group(:id)
            end
          elsif custom_lists_id_eq.present? && params[:order_by].blank? && custom_list.normal?
            @collection.result.reorder(MagicBean::CustomList.item_default_order)
          # params[:g]的组合目前都是给新品用的，所以这里判断g是否存在就行
          elsif params[:g].present? && params[:order_by].blank?
            # 新品需要根据开始售卖时间排序
            @collection.result.reorder("case when items.quantity > 0 then false else true end ASC, items.first_sale_at DESC, items.position ASC, items.created_at DESC")
          else
            @collection.result
          end

          @groupon_activities = MagicBean::GrouponActivity.published.going.where(item_id: @collection.page(params[:page].to_i).per(params[:per_page].to_i).padding(params[:offset].to_i).map(&:id))
          response_collection(params: { groupon_activities: @groupon_activities, is_new_user: is_new_user, like_item_ids: like_item_ids, active_top_left_item_hash: active_top_left_item_hash, exclusive_coupon_item_info: exclusive_coupon_item_info, buy_n_discount_item_info: buy_n_discount_item_info, preferential_pool_item_infos: preferential_pool_item_infos, allow_view_same_tag_items_info: allow_view_same_tag_items_info })
        end
      end

      desc "猜你喜欢", {
        success: API::Entities::SimpleItem,
        is_array: true,
        skip_authentication: true,
        detail: "目前最多只返回20条猜你喜欢商品数据"
      }
      get "guess_you_like" do
        item_ids = guess_you_like_item_ids

        if item_ids.blank?
          items = []
          @groupon_activities = []
        else
          items = (current_delivery_area ? MagicBean::Item : MagicBean::Item.not_merchant_delivery).includes(:translations, :on_sale_skus, :parent_category, brand: :translations, category: :translations)
            .on_sale_with_stock.not_gift.where(store_id: current_store_id, id: item_ids).send("#{ebest_channel}_channel").reorder_by_ids(item_ids)

          @groupon_activities = MagicBean::GrouponActivity.published.going.where(item_id: item_ids)
        end
        
        present items, with: API::Entities::SimpleItem, groupon_activities: @groupon_activities, is_new_user: is_new_user, like_item_ids: like_item_ids, active_top_left_item_hash: active_top_left_item_hash, exclusive_coupon_item_info: exclusive_coupon_item_info, buy_n_discount_item_info: buy_n_discount_item_info, preferential_pool_item_infos: preferential_pool_item_infos, allow_view_same_tag_items_info: allow_view_same_tag_items_info
      end

      desc "足迹（最近浏览）", {
        success: API::Entities::SimpleItem,
        is_array: true,
        detail: "足迹（最近浏览）"
      }
      paginate
      get "viewed" do
        present paginate(current_user.viewed_items), with: API::Entities::SimpleItem, is_new_user: is_new_user, like_item_ids: like_item_ids, active_top_left_item_hash: active_top_left_item_hash, exclusive_coupon_item_info: exclusive_coupon_item_info, buy_n_discount_item_info: buy_n_discount_item_info, preferential_pool_item_infos: preferential_pool_item_infos, allow_view_same_tag_items_info: allow_view_same_tag_items_info
      end

      desc "自动补全", {
        skip_authentication: true
      }
      params do
        requires :keyword, types: [String, Array], desc: "搜索商品标题、描述，多个关键字用空格分割", coerce_with: ->(val) { val.to_s.split(" ") }
        optional :item_type_eq, type: String, values: -> { MagicBean::Item.item_types.keys }, desc: "当日达商品才需要传"
      end
      get "autocomplete" do
        if MagicBean::Item.es_connected?
          MagicBean::Item.es_autocomplete(params[:keyword].join(" "), current_store_id, ebest_channel, search_delivery_types, params[:item_type_eq])
        else
          []
        end
      rescue
        []
      end

      desc "扫描条形码查找产品", {
        success: API::Entities::SimpleItem,
        skip_authentication: true
      }
      params do
        requires :barcode, types: String, desc: "条形码"
      end
      get "barcode_item" do
        item = end_of_association_chain.where(store_id: current_store_id).ransack(stock_keeping_units_barcode_eq: params[:barcode]).result.first

        if item
          present item, with: BeansApp::API::Entities::MinimalItem
        else
          response_error(I18n.t("error.item.not_found_in_current_store"))
        end
      end

      route_param :id do
        desc "商品详情", {
          success: API::Entities::Item,
          action_type: "viewed",
          page_type: "item",
          skip_authentication: true
        }
        params do
          optional :entity_type, type: String, values: ["base", "simple_detail", "detail", "simple_detail_v2", "detail_v2"], desc: "base只获取基础信息，simple_detail获取基础信息和sku信息, detail或不传则获取完整信息, simple_detail_v2和detail_v2是优化后的接口，没有返回properties_text，原接口兼容小程序"
        end
        get do
          entity = if params[:entity_type] == "base"
            BeansApp::API::Entities::SimpleItemWithMainImages
          elsif params[:entity_type] == "simple_detail"
            API::Entities::SimpleItemWithSku
          elsif params[:entity_type] == "simple_detail_v2"
            API::Entities::MinimalItemWithSku
          elsif params[:entity_type] == "detail_v2"
            save_user_history
            API::Entities::MinimalItemDetail
          else
            save_user_history
            API::Entities::Item
          end

          pending_sku_ids = current_user&.sku_in_stock_notices&.pending&.pluck(:stock_keeping_unit_id)

          # 详情接口无需传active_top_left_item_hash
          present resource, with: entity, is_new_user: is_new_user, item: resource, pending_sku_ids: pending_sku_ids
        end

        namespace :comments, desc: "评论列表" do
          desc "评论列表", {
            success: API::Entities::Comment,
            is_array: true,
            skip_authentication: true
          }
          paginate
          get do
            like_comment_ids = current_user&.like_comments&.ids || []
            present paginate(resource.comments.show.top_level.includes(:taggings, :reply).order(is_top: :desc, created_at: :desc).includes(:user)),
                    with: API::Entities::Comment, like_comment_ids: like_comment_ids
          end
        end

        namespace :item_nutrition_values, desc: "成分表数据" do
          desc "成分表数据", {
            success: API::Entities::ItemNutritionValue,
            is_array: true,
            skip_authentication: true
          }
          get do
            present resource.item_nutrition_values, with: API::Entities::ItemNutritionValue
          end
        end

        desc "相关商品", {
          success: API::Entities::SimpleItem,
          is_array: true,
          skip_authentication: true
        }
        paginate
        params do
          optional :item_type_eq, type: String, values: -> { MagicBean::Item.item_types.keys }, desc: "从当日达入口进入商品详情才需要传"
        end
        get "related_items" do
          tag_item_ids = MagicBean::Item.unscoped.on_sale.not_gift.send("#{ebest_channel}_channel").tagged_with(resource.tag_list, any: true).where(store_id: resource.store_id).ransack({ item_type_eq: params[:item_type_eq] }).result.reorder(position: :asc, created_at: :desc).ids
          category_item_ids = MagicBean::Item.unscoped.on_sale.not_gift.send("#{ebest_channel}_channel").where(category_id: resource.category_id, store_id: resource.store_id).ransack({ item_type_eq: params[:item_type_eq] }).result.reorder(position: :asc, created_at: :desc).ids
          target_ids = (tag_item_ids + category_item_ids).uniq - [resource.id]
          related_items = MagicBean::Item.unscoped.includes(:translations).on_sale.not_gift.includes(includes).where(id: target_ids, ae_drop_shipper: resource.ae_drop_shipper).reorder("CASE WHEN items.quantity = 0 THEN 1 ELSE 0 END, POSITION(id::text IN '#{target_ids.join(",")}')")
          @groupon_activities = MagicBean::GrouponActivity.published.going.where(item_id: related_items.select(:id))
          present paginate(related_items), with: API::Entities::SimpleItem, groupon_activities: @groupon_activities, is_new_user: is_new_user, like_item_ids: like_item_ids, active_top_left_item_hash: active_top_left_item_hash, exclusive_coupon_item_info: exclusive_coupon_item_info, buy_n_discount_item_info: buy_n_discount_item_info, preferential_pool_item_infos: preferential_pool_item_infos, allow_view_same_tag_items_info: allow_view_same_tag_items_info
        end

        desc "商品优惠详情",{
          skip_authentication: true
        }
        get "discounts" do
          if resource.pending?
            coupon_templates, sku_discounts, preferential_pool, promo_codes, gift_activity_rules = [], [], {}, [], []
          else
            if resource.coupon_enabled
              coupon_templates =
                (MagicBean::CouponTemplate.includes(:store, :translations).where("item_ids @> ARRAY[?]::integer[] OR category_ids @> ARRAY[?]::integer[] OR sub_category_ids @> ARRAY[?]::integer[] OR brand_ids @> ARRAY[?]::integer[] OR (custom_list_ids && ARRAY[?]::integer[])", resource.id, resource.parent_category_id, resource.category_id, resource.brand_id, resource.custom_list_ids)
                  .or(MagicBean::CouponTemplate.includes(:store, :translations).where(item_ids: [], category_ids: [], sub_category_ids: [], brand_ids: [], custom_list_ids: []))).active.item_display.where(store_id: [nil, resource.store_id]).map do |template|
                  {
                    id: template.id,
                    title: template.title,
                    code: template.code,
                    kind: template.kind,
                    denominations_in_cent: template.denominations_in_cent,
                    denominations_in_yuan: template.denominations_in_yuan,
                    at_least_amount_in_cent: template.at_least_amount_in_cent,
                    at_least_amount_in_yuan: template.at_least_amount_in_yuan,
                    discount: template.discount,
                    target_kind: template.target_kind,
                    time_kind: template.time_kind,
                    time_limit_in_day: template.time_limit_in_day,
                    start_at: template.start_at,
                    end_at: template.end_at,
                    details_image: template.details_image,
                    channel: template.channel,
                    delivery_types: template.delivery_types,
                    store_name: template.store&.name,
                    item_ids: template.item_ids,
                    category_ids: template.category_ids,
                    sub_category_ids: template.sub_category_ids,
                    brand_ids: template.brand_ids,
                    instruction: template.instruction
                  }
                end
            else
              coupon_templates = []
            end

            sku_discounts = resource.stock_keeping_units.map do |sku|
              next if sku.discount_quantity.blank? || sku.discount_price_in_cent.blank?

              {
                id: sku.id,
                properties_text: sku.properties_text,
                discount_quantity: sku.discount_quantity,
                discount_price_in_cent: sku.discount_price_in_cent,
                discount_price_in_yuan: sku.discount_price_in_yuan,
                image: sku.image
              }
            end.compact

            promo_codes = MagicBean::PromoCodeTemplate.active.item_display.where(store_id: [nil, resource.store_id], id: MagicBean::PromoStockKeepingUnit.where(stock_keeping_unit_id: resource.stock_keeping_units.ids).select(:promo_code_template_id)).map do |promo_template|
              {
                id: promo_template.id,
                title: promo_template.title,
                code: (promo_template.promo_codes.find_by(total_avaliable_count: 0) || promo_template.promo_codes.first)&.code
              }
            end

            preferential_pool = MagicBean::PreferentialPool.active_for_item(resource)

            # 赠品活动
            if resource.not_eligible_for_free_gift
              gift_activity_rules = []
            else
              gift_activity = MagicBean::GiftActivity.active.where(store_id: resource.store_id).first
              gift_activity_rules = gift_activity&.human_rules || []
            end
          end

          {
            coupon_templates: coupon_templates,
            sku_discounts: sku_discounts,
            preferential_pool: preferential_pool,
            promo_codes: promo_codes,
            gift_activity_rules: gift_activity_rules
          }
        end

        desc "商品标签", {
          success: API::Entities::ItemTagRelation,
          is_array: true,
          skip_authentication: true
        }
        get "item_tags" do
          item_tag_relations = MagicBean::ItemTagRelation.where(item_id: params[:id]).includes(item_tag: [:translations, item_tag_group: :translations]).order("allow_view_same_tag_items desc, id desc")
          present item_tag_relations, with: API::Entities::ItemTagRelation
        end
      end
    end
  end
end
