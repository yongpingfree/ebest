# frozen_string_literal: true

module BeansApp
  class API::V1::CustomLists < ::API
    # 自定义列表 API
    namespace :custom_list, desc: "自定义列表 API" do
      helpers ::ApiHelpers::ItemHelper

      helpers do
        def default_order
          "custom_lists.position asc, custom_lists.id desc"
        end

        def calculate_redis_key(params)
          "#{::MagicBean::CustomList::REDIS_API_KEY_NAMESPACE}#{params.to_s}_#{I18n.locale}_new_user_#{is_new_user}"
        end
      end
      desc "获取自定义列表", {
        success: API::Entities::CustomList,
        is_array: true,
        skip_authentication: true
      }
      paginate
      params do
        optional :id_in, type: Array[Integer],
          coerce_with: ->(val) { val.split(",").map(&:to_i) },
          desc: "自定义列表 ids"
        optional :delivery_area_id, type: Integer, desc: "送货上门区域 Id"
        optional :as_category_eq, type: Grape::API::Boolean, desc: "作为分类"
        optional :with_items, type: Grape::API::Boolean, desc: "是否返回items"
        optional :same_day_delivery, type: Grape::API::Boolean, desc: "是否只返回当日达商品"
        optional :items_limit, type: Integer, desc: "首次显示商品数"
        optional :id_count_map, type: Hash, desc: "自定义商品列表 ID 和对应商品数 map"
        optional :include_child_category, type: Grape::API::Boolean, desc: "是否返回作为二级分类的自定义类别"
        optional :parent_category_id_eq, type: Integer, desc: "一级分类 ID"
      end
      get do
        params[:store_id_eq] = current_store_id
        params[:with_items] = true if params[:with_items].nil?
        # as_category_eq为true，且没传一级分类，include_child_category为false，则过滤掉作为二级分类的自定义列表
        params[:parent_category_id_null] = true if params[:as_category_eq] && params[:parent_category_id_eq].blank? && !params[:include_child_category]

        id_count_map = params[:id_count_map]
        params[:id_in] = id_count_map.keys if id_count_map.present?

        redis_key = calculate_redis_key(params)
        redis_custom_list_str = Redis::Value.new(redis_key, compress: true, expireat: (Time.current + 5.minutes))

        unless redis_custom_list_str.value.nil?
          return present(JSON.parse(redis_custom_list_str.value))
        end

        delivery_area = MagicBean::DeliveryArea.find_by(id: current_delivery_area_id) if current_delivery_area_id.present?
        @includes = delivery_area ? [:translations, on_sale_custom_list_items: [item: [:translations, category: :translations]]] : [:translations, not_merchant_delivery_custom_list_items: [item: [:translations, category: :translations]]] if params[:with_items].present?

        @collection = end_of_association_chain.accessible_by(current_ability).ransack(ransack_params).result.includes(@includes).reorder(default_order).group(:id)
        @groupon_activities = MagicBean::GrouponActivity.published.going.where(store_id: current_store_id)

        is_limit = (params[:id_in] || []).length != 1

        result = response_collection(params: {
          delivery_area: delivery_area, groupon_activities: @groupon_activities,
          limit: is_limit, with_items: params[:with_items], items_limit: params[:items_limit],
          same_day_delivery: params[:same_day_delivery],
          is_new_user: is_new_user, id_count_map: id_count_map,
          like_item_ids: like_item_ids,
          active_top_left_item_hash: active_top_left_item_hash,
          exclusive_coupon_item_info: exclusive_coupon_item_info,
          buy_n_discount_item_info: buy_n_discount_item_info,
          preferential_pool_item_infos: preferential_pool_item_infos,
          allow_view_same_tag_items_info: allow_view_same_tag_items_info
        })
        redis_custom_list_str.value = result.to_json

        present result
      end

      route_param :id do
        desc "自定义列表详情", {
          success: API::Entities::CustomList,
          skip_authentication: true
        }
        params do
          optional :delivery_area_id, type: Integer, desc: "送货上门区域 Id"
        end
        get do
          @groupon_activities = MagicBean::GrouponActivity.published.going.where(store_id: current_store_id)
          response_resource(params: { delivery_area_id: current_delivery_area_id, groupon_activities: @groupon_activities, with_items: true, is_new_user: is_new_user, active_top_left_item_hash: active_top_left_item_hash,
            exclusive_coupon_item_info: exclusive_coupon_item_info, buy_n_discount_item_info: buy_n_discount_item_info, preferential_pool_item_infos: preferential_pool_item_infos, allow_view_same_tag_items_info: allow_view_same_tag_items_info })
        end

        desc "自定义商品列表", {
          success: API::Entities::CustomList,
          skip_authentication: true
        }
        params do
          optional :delivery_area_id, type: Integer, desc: "送货上门区域 Id"
          optional :item_type_eq, type: String, values: -> { MagicBean::Item.item_types.keys }, desc: "当日达商品才需要传"
        end
        paginate
        get "items" do
          target_entity = ::BeansApp::API::Entities::CustomListItem

          @items =
            if resource.normal?
              @groupon_activities = MagicBean::GrouponActivity.published.going.where(store_id: current_store_id)
              (current_delivery_area ? resource.on_sale_custom_list_items : resource.not_merchant_delivery_custom_list_items).includes(item: [:translations, category: :translations]).where("items.channels @> ARRAY['#{ebest_channel}']::varchar[]").ransack(item_item_type_eq: params[:item_type_eq]).result
            elsif resource.guess_you_like?
              target_entity = ::BeansApp::API::Entities::MinimalItem
              item_ids = guess_you_like_item_ids
              @groupon_activities = MagicBean::GrouponActivity.published.going.where(item_id: item_ids)
              (current_delivery_area ? MagicBean::Item : MagicBean::Item.not_merchant_delivery).includes(:translations, :on_sale_skus, category: :translations).on_sale_with_stock.not_gift
                .where(store_id: current_store_id).send("#{ebest_channel}_channel").where(id: item_ids).ransack(item_type_eq: params[:item_type_eq]).result.reorder_by_ids(item_ids)
            else
               # 设置了作为分类且为新品才需要过滤一级分类
              search_category_id = resource.as_category ? resource.parent_category_id : nil
              target_entity = ::BeansApp::API::Entities::MinimalItem
              @groupon_activities = MagicBean::GrouponActivity.published.going.where(store_id: current_store_id)
              (current_delivery_area ? MagicBean::Item : MagicBean::Item.not_merchant_delivery).includes(:translations, :on_sale_skus, category: :translations).on_sale.not_gift
                .where(store_id: current_store_id).send("#{ebest_channel}_channel").ransack(item_type_eq: params[:item_type_eq], ae_drop_shipper_eq: resource.ae_drop_shipper, g: MagicBean::Item.new_product_ransack_params, minor_category_parent_id_or_category_parent_id_eq: search_category_id).result
                .reorder("case when items.quantity > 0 then false else true end ASC, items.first_sale_at DESC, items.position ASC, items.created_at DESC")
            end

          present paginate(@items), with: target_entity, groupon_activities: @groupon_activities, is_new_user: is_new_user, like_item_ids: like_item_ids, active_top_left_item_hash: active_top_left_item_hash, exclusive_coupon_item_info: exclusive_coupon_item_info, buy_n_discount_item_info: buy_n_discount_item_info, preferential_pool_item_infos: preferential_pool_item_infos, allow_view_same_tag_items_info: allow_view_same_tag_items_info
        rescue ActiveRecord::RecordNotFound => e
          # 自定义列表接口有缓存，会导致数据如果被删除，请求items接口会404，但列表接口缓存条件比较复杂，没法在删除时清除对应缓存，所以这里返回空数组
          []
        end
      end
    end
  end
end
