# frozen_string_literal: true

module BeansApp
  class API::V1::WebCustomLists < ::API
    namespace :web_custom_lists, desc: "英文网站商品列表 API" do
      helpers do
        def default_order
          "position asc"
        end

        def calculate_redis_key(params)
          "#{::MagicBean::WebCustomList::REDIS_API_KEY_NAMESPACE}#{params.to_query}_#{I18n.locale}_new_user_#{is_new_user}"
        end

        def includes
          [:translations, items: [:on_sale_skus, :translations, :parent_category, brand: :translations]]
        end
      end
      desc "获取英文网站商品列表（先限制最多返回10个列表）", {
        success: API::Entities::WebCustomList,
        is_array: true,
        skip_authentication: true
      }
      paginate
      params do
        requires :page_location, type: String, values: MagicBean::WebCustomList.page_locations.keys, desc: "所属页面位置"
        optional :items_limit, type: Integer, default: 5, desc: "首次显示商品数，不传默认返回5个商品"
        optional :with_items, type: Grape::API::Boolean, desc: "是否返回items"
      end
      get do
        if current_user.present?
          params[:user_id] = current_user.id # 每个登录用户一个缓存 key，因为用户收藏的商品会不一样
        end
        params[:store_id] = current_store_id # 区分门店数据

        redis_key = calculate_redis_key(params)
        redis_custom_list_str = Redis::Value.new(redis_key, compress: true)

        unless redis_custom_list_str.value.nil?
          return present(JSON.parse(redis_custom_list_str.value))
        end

        # 设计稿首页主体位置只需要显示两个列表，其他位置暂时先返回 10 个商品列表
        list_limit = params[:page_location].to_s == "homepage_body" ? 2 : 10

        list = MagicBean::WebCustomList.includes(includes).where(store_id: current_store_id, displayed: true, page_location: params[:page_location]).order(position: :asc).first(list_limit)
        result = present list, with: API::Entities::WebCustomList,
                               items_limit: params[:items_limit],
                               with_items: params[:with_items],
                               like_item_ids: like_item_ids,
                               is_new_user: is_new_user

        redis_custom_list_str.value = result.to_json

        present result
      end

      route_param :id do
        desc "英文网站商品列表详情", {
          success: API::Entities::WebCustomList,
          skip_authentication: true
        }
        get do
          response_resource
        end

        desc "英文网站商品列表下属商品", {
          success: API::Entities::SimpleItem,
          skip_authentication: true
        }
        paginate
        get "items" do
          present paginate(resource.items.includes([:on_sale_skus, :translations, :parent_category]).send("#{ebest_channel}_channel").on_sale_with_stock.not_gift), with: API::Entities::SimpleItem, like_item_ids: like_item_ids, is_new_user: is_new_user, active_top_left_item_hash: active_top_left_item_hash, exclusive_coupon_item_info: exclusive_coupon_item_info, buy_n_discount_item_info: buy_n_discount_item_info, preferential_pool_item_infos: preferential_pool_item_infos, allow_view_same_tag_items_info: allow_view_same_tag_items_info
        end
      end
    end
  end
end
