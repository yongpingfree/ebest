# frozen_string_literal: true

module BeansApp
  class API::V1::Categories < ::API

    namespace :categories, desc: "分类API" do
      desc "分类列表", {
        success: API::Entities::Category,
        is_array: true,
        skip_authentication: true
      }
      paginate
      params do
        optional :parent_id, type: Integer, desc: "父分类"
        optional :with_children, type: Grape::API::Boolean, desc: "是否返回子分类"
        optional :with_items, type: Grape::API::Boolean, desc: "是否返回items"
        optional :same_day_delivery, type: Grape::API::Boolean, desc: "是否只返回当日达商品"
        optional :delivery_area_id, type: Integer, desc: "送货上门区域 Id"
        optional :ae_drop_shipper_eq, type: Boolean, default: false, desc: "是否是跨境购分类"
      end
      get do
        delivery_area = MagicBean::DeliveryArea.find_by(id: current_delivery_area_id) if current_delivery_area_id.present?
        same_day_delivery = params[:same_day_delivery]

        categories =
          if params[:parent_id].present?
            MagicBean::Category.children.where(parent_id: params[:parent_id]).has_items(current_store_id, ebest_channel, delivery_area, same_day_delivery)
          else
            MagicBean::Category.top.where(ae_drop_shipper: params[:ae_drop_shipper_eq])
          end

        show_on_web_query = ebest_channel == "web" ? true : [true, false]
        categories = categories.show.where(show_on_web: show_on_web_query).order(position: :desc)

        includes = [:translations]
        if params[:with_items] && params[:parent_id]
          @groupon_activities = MagicBean::GrouponActivity.published.going

          includes = delivery_area.present? ? (includes << [on_sale_items: [:on_sale_skus, :translations, :parent_category, brand: :translations]]) : (includes << [not_merchant_delivery_items: [:on_sale_skus, :translations, :parent_category, brand: :translations]])
        end

        # 只在分类页显示跳转分类
        has_items_category_ids = if params[:with_children]
          has_item_ids = MagicBean::Category.children.has_items(current_store_id, ebest_channel, delivery_area, same_day_delivery).map(&:id)
          if params[:parent_id].present?
            has_item_ids
          else
            jump_url_category_ids = MagicBean::Category.children.where(goto_kind: [:sctt_web, :url]).ids
            jump_url_category_ids + has_item_ids
          end
        else
          []
        end

        present(paginate(categories.includes(includes)),
          with: API::Entities::Category,
          with_children: params[:with_children],
          with_items: params[:with_items],
          same_day_delivery: same_day_delivery,
          delivery_area: delivery_area,
          groupon_activities: @groupon_activities,
          store_id: current_store_id,
          has_items_category_ids: has_items_category_ids,
          show_on_web_query: show_on_web_query,
          is_new_user: is_new_user,
          like_item_ids: like_item_ids,
          active_top_left_item_hash: active_top_left_item_hash,
          exclusive_coupon_item_info: exclusive_coupon_item_info,
          buy_n_discount_item_info: buy_n_discount_item_info,
          preferential_pool_item_infos: preferential_pool_item_infos,
          allow_view_same_tag_items_info: allow_view_same_tag_items_info
        )
      end

      desc "搜索带商品关键词的一级分类", {
        success: API::Entities::ParentCategory,
        is_array: true,
        skip_authentication: true
      }
      params do
        optional :item_keyword, types: [String, Array], desc: "搜索商品标题、描述，多个关键字用空格分割", coerce_with: ->(val) { Ropencc.conv("t2s.json", val.to_s).split(" ") }
        optional :ae_drop_shipper_eq, type: Boolean, default: false, desc: "是否是跨境购分类"
      end
      get :of_items do
        if params[:item_keyword].blank?
          result = MagicBean::Category.show.includes(:translations).where(parent_id: nil, ae_drop_shipper: params[:ae_drop_shipper_eq])
        else
          if MagicBean::Item.es_connected?
            search_params = { keyword: params[:item_keyword].join(" "), store_id: current_store_id, channel: ebest_channel, delivery_types: search_delivery_types }
            parent_ids = MagicBean::Item.es_search(search_params, 1, 9999).map(&:parent_category_id).uniq
            result = MagicBean::Category.show.includes(:translations).where(parent_id: nil, id: parent_ids)
          else
            # 过滤掉gift_only的商品
            basic_relation = MagicBean::Category.show.includes(:translations).where(parent_id: nil, ae_drop_shipper: params[:ae_drop_shipper_eq]).joins(:parent_category_items).where(
              items: { listing_type: ["online", "advance_on"], store_id: current_store_id }
            ).where("items.gift_only = false and items.channels @> ARRAY['#{ebest_channel}']::varchar[]")
            query_matched_with_tags_name = basic_relation.ransack(
              parent_category_items_tags_name_cont_any: params[:item_keyword]
            )
            query_matched_with_title = basic_relation.ransack(
              parent_category_items_info_cont_any: params[:item_keyword]
            )
            result = [query_matched_with_tags_name.result, query_matched_with_title.result].flatten.uniq.sort_by { |category| category.position }
          end
        end

        present result, with: API::Entities::ParentCategory
      end

      desc "搜索带拍卖关键词的一级分类", {
        success: API::Entities::ParentCategory,
        is_array: true,
        skip_authentication: true
      }
      params do
        optional :auction_activities_keyword, types: [String, Array], desc: "搜索拍卖标题、描述，多个关键字用空格分割", coerce_with: ->(val) { val.to_s.split(" ") }
        optional :ae_drop_shipper_eq, type: Boolean, default: false, desc: "是否是跨境购分类"
      end
      get :of_auction_activities do
        auction_activities = MagicBean::Auction::Activity.show_on_app.ransack(store_id_eq: current_store_id, keyword_cont_any: params[:auction_activities_keyword]).result

        category_ids = (auction_activities.pluck(:category_id) + auction_activities.pluck(:minor_category_id)).uniq

        # 最多先返回 50 个分类，不够再调整
        categories = MagicBean::Category.includes(:translations).where(id: category_ids, ae_drop_shipper: params[:ae_drop_shipper_eq]).order(position: :asc).first(50)
        present categories, with: API::Entities::ParentCategory
      end
    end
  end
end
