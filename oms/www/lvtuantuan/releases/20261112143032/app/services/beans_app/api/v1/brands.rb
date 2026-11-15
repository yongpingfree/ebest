# frozen_string_literal: true

module BeansApp
  class API::V1::Brands < ::API
    # TODO: 确认最终返回的品牌数，或者是否全部返回
    MAX_BRAND_LENGTH_OF_ITEMS_SEARCHED = 30

    namespace :brands, desc: "品牌API" do

      helpers do
        def default_order
          "CASE WHEN cover IS NULL OR cover = '' THEN 1 ELSE 0 END ASC, created_at DESC"
        end

        def includes
          [:translations]
        end
      end

      desc "品牌列表", {
        success: API::Entities::Brand,
        is_array: true,
        skip_authentication: true
      }
      params do
        optional :category_id, type: Integer, desc: "一级分类ID"
      end
      paginate
      get do
        if params[:category_id].present?
          params[:id_in] = MagicBean::Item.ransack(parent_category_id_eq: params[:category_id]).result.pluck(:brand_id).uniq
        end
        authorize_and_response_collection
      end

      desc "搜索带商品关键词的品牌", {
        success: API::Entities::Brand,
        is_array: true,
        skip_authentication: true,
        detail: "最多返回#{MAX_BRAND_LENGTH_OF_ITEMS_SEARCHED}个品牌"
      }
      params do
        optional :item_keyword, types: [String, Array], desc: "搜索商品标题、描述，多个关键字用空格分割", coerce_with: ->(val) { val.to_s.strip.split(" ") }
        optional :category_id_eq, type: Integer, desc: "产品分类ID"
        optional :category_parent_id_eq, type: Integer, desc: "一级分类ID"
        optional :custom_lists_id_eq, type: Integer, desc: "自定义列表ID"
        optional :ae_drop_shipper_eq, type: Boolean, default: false, desc: "是否跨境购"
        optional :brand_id_in, type: Array[Integer],
          coerce_with: ->(val) { val.split(",").map(&:to_i) },
          desc: "品牌ids"
      end
      get :of_items do
        item_query = {
          listing_type_in: ["online", "advance_on"],
          store_id_eq: current_store_id,
          ae_drop_shipper_eq: params[:ae_drop_shipper_eq]
        }

        if params[:item_keyword].present?
          if MagicBean::Item.es_connected?
            search_params = { keyword: params[:item_keyword].join(" "), store_id: current_store_id, channel: ebest_channel, delivery_types: search_delivery_types }
            brand_ids = MagicBean::Item.es_search(search_params, 1, 9999).map(&:brand_id).uniq
          else
            query_matched_with_title = item_query.merge(
              translated_searchable_title_or_translated_searchable_description_cont_any: params[:item_keyword]
            )
            matched_title_brand_ids = MagicBean::Item.unscoped.not_gift.send("#{ebest_channel}_channel").ransack(query_matched_with_title).result.pluck(:brand_id)
  
            matched_tag_brand_ids = MagicBean::Item.unscoped.not_gift.send("#{ebest_channel}_channel").tagged_with(params[:item_keyword]).ransack(item_query).result.pluck(:brand_id)
  
            brand_ids = matched_tag_brand_ids + matched_title_brand_ids  
          end
        elsif params[:category_id_eq].present?
          query_matched_with_category = item_query.merge(
            minor_category_id_or_category_id_eq: params[:category_id_eq]
          )
          brand_ids = MagicBean::Item.unscoped.not_gift.send("#{ebest_channel}_channel").ransack(query_matched_with_category).result.select(:brand_id)
        elsif params[:category_parent_id_eq].present?
          if ebest_channel == "web"
            query_matched_with_parent_category = item_query.merge(
              minor_web_category_parent_id_or_web_category_parent_id_eq: params[:category_parent_id_eq]
            )
          else
            query_matched_with_parent_category = item_query.merge(
              minor_category_parent_id_or_category_parent_id_eq: params[:category_parent_id_eq]
            )
          end

          brand_ids = MagicBean::Item.unscoped.not_gift.send("#{ebest_channel}_channel").ransack(query_matched_with_parent_category).result.select(:brand_id)
        elsif params[:custom_lists_id_eq].present?
          query_matched_with_custom_list = item_query.merge(
            custom_lists_id_eq: params[:custom_lists_id_eq]
          )
          brand_ids = MagicBean::Item.unscoped.not_gift.send("#{ebest_channel}_channel").ransack(query_matched_with_custom_list).result.select(:brand_id)
        else
          brand_ids = MagicBean::Brand.all.order(position: :asc).select(:id)
        end

        result = MagicBean::Brand.includes(:translations).where(id: brand_ids).ransack({ id_in: params[:brand_id_in] }).result.order(position: :asc).first(MAX_BRAND_LENGTH_OF_ITEMS_SEARCHED)

        present result, with: API::Entities::Brand
      end
    end
  end
end
