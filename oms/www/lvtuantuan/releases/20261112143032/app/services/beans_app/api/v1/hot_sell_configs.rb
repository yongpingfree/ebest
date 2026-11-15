# frozen_string_literal: true

module BeansApp
  class API::V1::HotSellConfigs < ::API
    # 热卖榜 API
    namespace :hot_sell_configs, desc: "热卖榜 API" do
      helpers BeansAdmin::Helpers::HotSellConfigsHelper
      helpers do
        def default_order
          ["position ASC", "created_at DESC"]
        end

        def includes
          [category: :translations]
        end

        def end_of_association_chain
          resource_class.where(enabled: true)
        end
      end

      desc "获取热卖榜列表", {
        success: API::Entities::SimpleHotSellConfig,
        is_array: true,
        skip_authentication: true
      }
      paginate
      get do
        params[:store_id_eq] = current_store_id
        authorize_and_response_collection
      end

      route_param :id do
        desc "获取热卖榜SKU列表", {
          success: API::Entities::SimpleItem,
          skip_authentication: true
        }
        params do
          optional :ae_drop_shipper_eq, type: Grape::API::Boolean, desc: "true 为跨境购商品"
        end
        paginate
        get "items" do
          includes = [:on_sale_skus, :parent_category, :parent_web_category, :translations, brand: :translations, category: :translations]
          items = MagicBean::Item.unscoped.on_sale.not_gift.includes(includes).where(hot_sell_config_id: params[:id], ae_drop_shipper: params[:ae_drop_shipper_eq]).where.not(hot_sell_ranking: nil).reorder("hot_sell_ranking asc, id desc")

          @groupon_activities = MagicBean::GrouponActivity.published.going.where(item_id: items.page(params[:page].to_i).per(params[:per_page].to_i).padding(params[:offset].to_i).map(&:id))

          present paginate(items), with: API::Entities::SimpleItem, groupon_activities: @groupon_activities, is_new_user: is_new_user, like_item_ids: like_item_ids, active_top_left_item_hash: active_top_left_item_hash,
            exclusive_coupon_item_info: exclusive_coupon_item_info, buy_n_discount_item_info: buy_n_discount_item_info, preferential_pool_item_infos: preferential_pool_item_infos, allow_view_same_tag_items_info: allow_view_same_tag_items_info
        end
      end
    end
  end
end
