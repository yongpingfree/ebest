# frozen_string_literal: true

module BeansApp
  class API::V1::SameDayDeliveryCartItems < ::API
    namespace :same_day_delivery_cart_items, desc: "当日达购物车API" do

      helpers do
        def my_shopping_cart_items
          # 有时会出现没shopping_cart的用户，产生原因待确认
          (current_user.same_day_delivery_cart || current_user.send(:create_same_day_delivery_cart)).same_day_delivery_cart_items
        end

        def active_promotion_prices
          @active_promotion_prices ||= MagicBean::TimeLimitedPromotionPrice.active.where(store_id: current_store_id).inject({}) do |hash, price|
            hash.merge(price.stock_keeping_unit_id => [price.price_in_cent, price.price_in_yuan])
          end
        end
      end

      desc "当日达购物车商品", {
        success: API::Entities::SameDayDeliveryCartItem
      }
      get do
        present my_shopping_cart_items, with: API::Entities::SameDayDeliveryCartItem, is_new_user: is_new_user, active_top_left_item_hash: active_top_left_item_hash, exclusive_coupon_item_info: exclusive_coupon_item_info, buy_n_discount_item_info: buy_n_discount_item_info, preferential_pool_item_infos: preferential_pool_item_infos, allow_view_same_tag_items_info: allow_view_same_tag_items_info
      end

      desc "当日达购物车商品数量(新)"
      get "count" do
        { count: my_shopping_cart_items.includes(:stock_keeping_unit).select { |sci| sci.stock_keeping_unit.is_on_sale? }.sum(&:quantity) }
      end

      desc "购物车商品(多店)", {
        success: API::Entities::StoreSameDayDeliveryCartItem
      }
      get "group_list" do
        includes_relations = [stock_keeping_unit: [item: [:on_sale_skus, :store, :translations]]]
        my_shopping_cart_items_group = my_shopping_cart_items.includes(includes_relations).order(created_at: :desc).group_by { |item| item.store_id }
        store_shopping_cart_items = my_shopping_cart_items_group.keys.map do |k|
          sort_cart_items = my_shopping_cart_items_group[k].partition { |cart_item| cart_item.stock_keeping_unit.is_on_sale? }.flatten

          {
            store: MagicBean::Store.find(k),
            same_day_delivery_cart_items: sort_cart_items
          }
        end

        pending_sku_ids = current_user.sku_in_stock_notices.pending.pluck(:stock_keeping_unit_id)

        # 为了跟原购物车数据结构保持一致，这里使用这种写法
        store_shopping_cart_items = JSON.parse(
          BeansApp::API::Entities::StoreSameDayDeliveryCartItem.represent(
            store_shopping_cart_items, serializable: true,
            pending_sku_ids: pending_sku_ids,
            is_new_user: current_user.new_user,
            active_top_left_item_hash: active_top_left_item_hash
          ).to_json
        )

        store_shopping_cart_items.each do |store_shopping_cart_item|
          store_shopping_cart_item["same_day_delivery_cart_items"].each do |item|
            sku_id = item["stock_keeping_unit"]["id"].to_i
            promo_price = active_promotion_prices[sku_id]
            # 当优惠价格小于sku价格才替换
            if promo_price.present? && promo_price[0] < item["stock_keeping_unit"]["price_in_cent"]
              item["stock_keeping_unit"]["price_in_cent"] = promo_price[0]
              item["stock_keeping_unit"]["price_in_yuan"] = promo_price[1]
            end
          end
        end

        present store_shopping_cart_items
      end

      desc "购物车商品数量", {
        detail: <<-NOTES.strip_heredoc
          ```json
          {
            quantity: 2
          }
          ```
        NOTES
      }
      get "quantity" do
        present quantity: my_shopping_cart_items.sum(:quantity)
      end

      desc "添加到购物车", {
        success: API::Entities::SameDayDeliveryCartItem
      }
      params do
        requires :stock_keeping_unit_id, type: Integer, desc: "商品 ID"
        requires :quantity, type: Integer, desc: "商品数量"
        optional :source_page_name, type: String, values: MagicBean::SameDayDeliveryCartItem.source_page_names.keys, desc: "页面名"
        # optional :source_custom_list_id, type: Integer,  desc: "自定义页面id（source额外参数传 source_extra_hash，hash类型，grape没法只定义空hash就在这里说明了）"
      end
      post do
        Analyses::Cache.incr("same_day_shop_bag_item_count", Date.current)
        stock_keeping_unit = MagicBean::StockKeepingUnit.find params[:stock_keeping_unit_id]
        response_error(I18n.t("error.item.virtual_item_can_not_add_to_cart")) if stock_keeping_unit.item.is_virtual
        response_error(I18n.t("error.item.gift_only_item_can_not_add_to_cart")) if stock_keeping_unit.gift_only
        response_error(I18n.t("error.item.not_same_day_item_cant_not_add_to_cart")) unless stock_keeping_unit.item.same_day_delivery?

        shopping_cart_item = my_shopping_cart_items.with_deleted.find_by(
          stock_keeping_unit_id: stock_keeping_unit.id
        )

        source_custom_list_id = params[:source_custom_list_id] == "fixed" ? nil : params[:source_custom_list_id]

        # 如果该商品已经存在，则更新数量
        # 购物车商品对象使用软删除，如果找出旧的数据，依旧更新
        # 否则新创建
        if shopping_cart_item
          if shopping_cart_item.deleted?
            shopping_cart_item.quantity = params[:quantity]
            shopping_cart_item.deleted_at = nil
          else
            shopping_cart_item.quantity = shopping_cart_item.quantity + params[:quantity]
          end

          shopping_cart_item.source_page_name = params[:source_page_name] if params[:source_page_name]
          shopping_cart_item.source_custom_list_id = source_custom_list_id if params[:source_page_name].present? || source_custom_list_id.present?
          shopping_cart_item.source_extra_hash = params[:source_extra_hash] if params[:source_page_name].present? || params[:source_extra_hash].present?
          shopping_cart_item.source_channel = ebest_channel if ebest_channel
        else
          params[:source_channel] = ebest_channel
          shopping_cart_item = my_shopping_cart_items.new(shopping_cart_item_params)
        end

        if is_new_user && stock_keeping_unit.new_user_buy_quota_invalid?(shopping_cart_item.quantity, current_user)
          response_error I18n.t("grape.shopping_cart_items.new_user_buy_quota", title: stock_keeping_unit.human_title, quota: stock_keeping_unit.new_user_buy_quota)
        end

        begin
          if shopping_cart_item.save
            response_success
          else
            response_record_error shopping_cart_item
          end
        rescue ActiveRecord::RecordNotUnique
          response_error I18n.t("grape.shopping_cart_items.record_not_unique")
        end
      end

      desc "批量移除购物车", {
        detail: <<-NOTES.strip_heredoc
            ```json
            {
              code: 200,
              message: "ok"
            }
            ```
        NOTES
      }
      params do
        requires :ids, type: Array[Integer], desc: "shopping cart item ids"
      end
      delete "batch" do
        items = my_shopping_cart_items.where id: params[:ids]

        response_success if items.blank?

        items.delete_all

        response_success
      end

      desc "批量移入收藏夹", {
        detail: <<-NOTES.strip_heredoc
            ```json
            {
              code: 200,
              message: "ok"
            }
            ```
        NOTES
      }
      params do
        requires :ids, type: Array[Integer], desc: "shopping cart item ids"
      end
      put "like_and_remove" do
        cart_items = my_shopping_cart_items.where id: params[:ids]

        response_success if cart_items.blank?

        cart_items.each do |cart_item|
          current_user.create_action(:like, target: cart_item.item)
        end

        cart_items.delete_all

        response_success
      end

      desc "清空门店购物车", {
        detail: <<-NOTES.strip_heredoc
            ```json
            {
              code: 200,
              message: "ok"
            }
            ```
        NOTES
      }
      params do
        requires :store_id, type: Integer
      end
      delete "empty" do
        items = my_shopping_cart_items.where store_id: params[:store_id]

        response_success if items.blank?

        items.delete_all

        response_success
      end

      desc "购物车推荐商品"
      paginate
      get "recommend_items" do
        sort_item_ids = []
        if current_user.member
          all_sort_item_ids = MagicBean::OrderItem.where(order_id: current_user.same_day_delivery_orders.paid.where(store_id: current_store_id).select(:id)).group(:item_id).count.sort_by { |_key, value| -value }.to_h.keys
          if all_sort_item_ids.present?
            sort_item_ids += MagicBean::Item.send("#{ebest_channel}_channel").on_sale_with_stock.not_gift.same_day_delivery.where(id: all_sort_item_ids).where.not(parent_category_id: [185, 331]).reorder_by_ids(all_sort_item_ids).first(25).pluck(:id)
          end
        end
        sort_item_ids += MagicBean::Item.send("#{ebest_channel}_channel").on_sale.not_gift.same_day_delivery.where(store_id: current_store_id).where.not(strikethrough_price_in_cent: [nil, 0], parent_category_id: [185, 331]).where("quantity > 0 and strikethrough_price_in_cent > price_in_cent").reorder("price_in_cent::decimal/strikethrough_price_in_cent asc").first(25).pluck(:id)
        sort_item_ids = sort_item_ids.uniq

        if sort_item_ids.present?
          items = MagicBean::Item.includes(:translations).where(id: sort_item_ids).reorder_by_ids(sort_item_ids)
          present paginate(items), with: BeansApp::API::Entities::SimpleItem, is_new_user: is_new_user, active_top_left_item_hash: active_top_left_item_hash, exclusive_coupon_item_info: exclusive_coupon_item_info, buy_n_discount_item_info: buy_n_discount_item_info, preferential_pool_item_infos: preferential_pool_item_infos, allow_view_same_tag_items_info: allow_view_same_tag_items_info
        else
          []
        end
      end

      route_param :id do

        helpers do
          def current_shopping_cart_item
            my_shopping_cart_items.find(params[:id])
          end
        end

        desc "从购物车中移除", {
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
          item = my_shopping_cart_items.find_by id: params[:id]

          return response_success if item.nil?

          if item.destroy
            response_success
          else
            response_record_error(item)
          end
        end

        desc "更新商品数量", {
          detail: <<-NOTES.strip_heredoc
            ```json
            {
              code: 200,
              message: "ok"
            }
            ```
          NOTES
        }
        params do
          requires :quantity, type: Integer, desc: "商品数量"
        end
        put do
          cart_item = current_shopping_cart_item
          stock_keeping_unit = cart_item.stock_keeping_unit

          if is_new_user && stock_keeping_unit.new_user_buy_quota_invalid?(params[:quantity], current_user)
            response_error I18n.t("grape.shopping_cart_items.new_user_buy_quota", title: stock_keeping_unit.human_title, quota: stock_keeping_unit.new_user_buy_quota)
          end

          if cart_item.update(quantity: params[:quantity])
            response_success
          else
            response_record_error(cart_item)
          end
        end
      end
    end
  end
end
