# frozen_string_literal: true

module BeansApp
  class API::V1::WebCategories < ::API
    namespace :web_categories, desc: "网站分类API" do
      desc "网站分类列表", {
        success: API::Entities::WebCategory,
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
      end
      get do
        delivery_area = MagicBean::DeliveryArea.find_by(id: current_delivery_area_id) if current_delivery_area_id.present?
        same_day_delivery = params[:same_day_delivery]

        categories =
          if params[:parent_id].present?
            MagicBean::WebCategory.children.where(parent_id: params[:parent_id]).has_items(current_store_id, ebest_channel, delivery_area, same_day_delivery)
          else
            MagicBean::WebCategory.top
          end

        categories = categories.show.order(position: :desc)

        includes = [:translations]
        if params[:with_items] && params[:parent_id]
          @groupon_activities = MagicBean::GrouponActivity.published.going

          includes = delivery_area.present? ? (includes << [on_sale_items: [:on_sale_skus, :translations, :parent_category, brand: :translations]]) : (includes << [not_merchant_delivery_items: [:on_sale_skus, :translations, :parent_category, brand: :translations]])
        end

        has_items_category_ids = if params[:with_children]
                                   MagicBean::WebCategory.children.has_items(current_store_id, ebest_channel, delivery_area, same_day_delivery).map(&:id)
                                 else
                                   []
                                 end

        present(paginate(categories.includes(includes)),
          with: API::Entities::WebCategory,
          with_children: params[:with_children],
          with_items: params[:with_items],
          same_day_delivery: same_day_delivery,
          delivery_area: delivery_area,
          groupon_activities: @groupon_activities,
          store_id: current_store_id,
          has_items_category_ids: has_items_category_ids,
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
        success: API::Entities::ParentWebCategory,
        is_array: true,
        skip_authentication: true
      }
      params do
        optional :item_keyword, types: [String, Array], desc: "搜索商品标题、描述，多个关键字用空格分割", coerce_with: ->(val) { Ropencc.conv("t2s.json", val.to_s).split(" ") }
      end
      get :of_items do
        if params[:item_keyword].blank?
          result = MagicBean::WebCategory.show.includes(:translations).where(parent_id: nil)
        else
          basic_relation = MagicBean::WebCategory.show.includes(:translations).where(parent_id: nil).joins(:parent_category_items).where(
            items: { listing_type: ["online", "advance_on"], store_id: current_store_id }
          ).where("items.channels @> ARRAY['#{ebest_channel}']::varchar[]")
          query_matched_with_tags_name = basic_relation.ransack(
            parent_category_items_tags_name_cont_any: params[:item_keyword]
          )
          query_matched_with_title = basic_relation.ransack(
            parent_category_items_info_cont_any: params[:item_keyword]
          )
          result = [query_matched_with_tags_name.result, query_matched_with_title.result].flatten.uniq.sort_by { |category| category.position }
        end

        present result, with: API::Entities::ParentWebCategory
      end
    end
  end
end
