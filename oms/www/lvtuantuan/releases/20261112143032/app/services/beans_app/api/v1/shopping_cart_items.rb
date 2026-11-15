# frozen_string_literal: true

module BeansApp
  class API::V1::ShoppingCartItems < ::API
    namespace :shopping_cart_items, desc: "购物车API" do

      helpers do
        def my_shopping_cart_items
          # 有时会出现没shopping_cart的用户，产生原因待确认
          (current_user.shopping_cart || current_user.send(:create_shopping_cart)).shopping_cart_items.where(store_id: current_store_id)
        end

        def active_promotion_prices
          @active_promotion_prices ||= MagicBean::TimeLimitedPromotionPrice.active.where(store_id: current_store_id).inject({}) do |hash, price|
            hash.merge(price.stock_keeping_unit_id => [price.price_in_cent, price.price_in_yuan])
          end
        end
      end

      desc "购物车商品", {
        success: API::Entities::ShoppingCartItem
      }
      get do
        present my_shopping_cart_items, with: API::Entities::ShoppingCartItem, is_new_user: is_new_user, active_top_left_item_hash: active_top_left_item_hash, exclusive_coupon_item_info: exclusive_coupon_item_info, buy_n_discount_item_info: buy_n_discount_item_info, preferential_pool_item_infos: preferential_pool_item_infos, allow_view_same_tag_items_info: allow_view_same_tag_items_info
      end

      desc "购物车商品数量(新)"
      get "count" do
        { 
          count: my_shopping_cart_items.includes([stock_keeping_unit: [item: :on_sale_skus]]).select { |sci| sci.stock_keeping_unit.is_on_sale? && !sci.stock_keeping_unit.item.ae_drop_shipper }.sum(&:quantity),
          ae_drop_shipper_count: my_shopping_cart_items.includes([stock_keeping_unit: [item: :on_sale_skus]]).select { |sci| sci.stock_keeping_unit.is_on_sale? && sci.stock_keeping_unit.item.ae_drop_shipper }.sum(&:quantity)
        }
      end

      # app现在只有单店，接口逻辑改为返回当前门店的商品
      desc "购物车商品(多店)", {
        success: API::Entities::StoreShoppingCartItem
      }
      params do
        optional :full, type: Boolean, default: true, desc: "是否请求完整购物车数据"
      end
      get "group_list" do
        # 如果后面重新用缓存，clear_gift_only_cart_items和clear_virtual_cart_items这两个方法需要处理缓存问题
        # store_shopping_cart_items = current_user.get_redis_store_shopping_cart_items(current_postal_code, current_suburb, params[:full])
        # fresh_cached = false

        # if store_shopping_cart_items.blank?
          store_shopping_cart_items = current_user.set_redis_store_shopping_cart_items(current_postal_code, current_suburb, current_store_id, params[:full])
          fresh_cached = true
        # end

        unless fresh_cached
          sku_ids = my_shopping_cart_items.pluck(:stock_keeping_unit_id)
          inventory = MagicBean::StockKeepingUnit.where(id: sku_ids).pluck(:id, :quantity).to_h
        end

        store_shopping_cart_items.each do |store_shopping_cart_item|
          store_shopping_cart_item["shopping_cart_items"].each do |item|
            sku_id = item["stock_keeping_unit"]["id"].to_i
            item["stock_keeping_unit"]["quantity"] = inventory[sku_id] unless fresh_cached
            promo_price = active_promotion_prices[sku_id]
            # set_redis_store_shopping_cart_items里面拿到的sku价格已经计算过一轮优惠价了，但这里为了保险，还是再比对
            # 当优惠价格小于sku价格才替换
            if promo_price.present? && promo_price[0] < item["stock_keeping_unit"]["price_in_cent"]
              item["stock_keeping_unit"]["price_in_cent"] = promo_price[0]
              item["stock_keeping_unit"]["price_in_yuan"] = promo_price[1]
            end

            # 比对price_in_cent和original_price_in_cent，给sku设置划线价
            if item["stock_keeping_unit"]["price_in_cent"] < item["stock_keeping_unit"]["original_price_in_cent"]
              item["stock_keeping_unit"]["strikethrough_price_in_cent"] = [item["stock_keeping_unit"]["original_price_in_cent"], item["stock_keeping_unit"]["strikethrough_price_in_cent"]].compact.max
              item["stock_keeping_unit"]["strikethrough_price_in_yuan"] = ActiveSupport::NumberHelper.number_to_currency(item["stock_keeping_unit"]["strikethrough_price_in_cent"].to_i / 100.0, format: "%n", delimiter: "")
            end
          end
        end

        present store_shopping_cart_items
      end

      desc "购物车商品预计送达时间", {
        success: API::Entities::StockKeepingUnitDeliveryTime
      }
      get "delivery_times" do
        # skus_with_delivery_time = current_user.get_redis_shopping_cart_items_delivery_time(current_postal_code, current_suburb)
        # if skus_with_delivery_time.blank?
          skus_with_delivery_time = current_user.set_redis_shopping_cart_items_delivery_time(current_postal_code, current_suburb)
        # end

        present skus_with_delivery_time
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
        success: API::Entities::ShoppingCartItem
      }
      params do
        requires :stock_keeping_unit_id, type: Integer, desc: "商品 ID"
        requires :quantity, type: Integer, desc: "商品数量"
        optional :source_page_name, type: String, values: MagicBean::ShoppingCartItem.source_page_names.keys, desc: "页面名"
        # optional :source_custom_list_id, type: Integer,  desc: "自定义页面id（source额外参数传 source_extra_hash，hash类型，grape没法只定义空hash就在这里说明了）"
        optional :live_top, type: Boolean, desc: "直播间置顶并免邮"
      end
      post do
        Analyses::Cache.incr("shop_bag_item_count", Date.current)
        stock_keeping_unit = MagicBean::StockKeepingUnit.find params[:stock_keeping_unit_id]
        response_error(I18n.t("error.item.virtual_item_can_not_add_to_cart")) if stock_keeping_unit.item.is_virtual
        response_error(I18n.t("error.item.gift_only_item_can_not_add_to_cart")) if stock_keeping_unit.gift_only
       
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
          shopping_cart_item.live_top = params[:live_top] unless params[:live_top].nil?
        else
          params[:source_channel] = ebest_channel
          params.delete(:live_top) if params[:live_top].nil?
          shopping_cart_item = my_shopping_cart_items.new(shopping_cart_item_params)
        end

        if is_new_user && stock_keeping_unit.new_user_buy_quota_invalid?(shopping_cart_item.quantity, current_user)
          response_error I18n.t("grape.shopping_cart_items.new_user_buy_quota", title: stock_keeping_unit.human_title, quota: stock_keeping_unit.new_user_buy_quota)
        end

        begin
          if shopping_cart_item.save
            # UpdateRedisShoppingCartItemsJob.perform_later(current_user, current_postal_code, current_suburb, current_store_id)

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

        return response_success if items.blank?

        items.delete_all

        # 避免切换地址商品不正确
        current_user.reset_redis_store_shopping_cart_items
        UpdateRedisShoppingCartItemsJob.perform_later(current_user, current_postal_code, current_suburb, current_store_id)

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

        return response_success if cart_items.blank?

        cart_items.each do |cart_item|
          current_user.create_action(:like, target: cart_item.item)
        end

        cart_items.delete_all

        # 避免切换地址商品不正确
        current_user.reset_redis_store_shopping_cart_items
        UpdateRedisShoppingCartItemsJob.perform_later(current_user, current_postal_code, current_suburb, current_store_id)

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
        optional :ae_drop_shipper_eq, type: Boolean, default: false, desc: "是否是跨境购商品"
      end
      delete "empty" do
        items = my_shopping_cart_items.where(store_id: params[:store_id]).ransack(stock_keeping_unit_item_ae_drop_shipper_eq: params[:ae_drop_shipper_eq]).result

        return response_success if items.blank?

        items.delete_all

        current_user.reset_redis_store_shopping_cart_items

        response_success
      end

      desc "购物车推荐商品"
      params do
        optional :ae_drop_shipper_eq, type: Boolean, default: false, desc: "是否是跨境购商品"
      end
      paginate
      get "recommend_items" do
        # FIXME: 跨境购推荐商品先返回空
        return [] if params[:ae_drop_shipper_eq]
        # 教育中心 185 和玩轉澳洲 331 先写死过滤掉这两个分类的产品
        sort_item_ids = []
        if current_user.member
          all_sort_item_ids = MagicBean::OrderItem.where(order_id: current_user.orders.paid.where(store_id: current_store_id, ae_drop_shipper: params[:ae_drop_shipper_eq]).select(:id)).group(:item_id).count.sort_by { |_key, value| -value }.to_h.keys
          if all_sort_item_ids.present?
            sort_item_ids += MagicBean::Item.send("#{ebest_channel}_channel").on_sale_with_stock.not_gift.where(id: all_sort_item_ids).where.not(parent_category_id: [185, 331]).reorder_by_ids(all_sort_item_ids).first(25).pluck(:id)
          end
        end
        sort_item_ids += MagicBean::Item.send("#{ebest_channel}_channel").on_sale.not_gift.where(store_id: current_store_id, ae_drop_shipper: params[:ae_drop_shipper_eq]).where.not(strikethrough_price_in_cent: [nil, 0], parent_category_id: [185, 331]).where("quantity > 0 and strikethrough_price_in_cent > price_in_cent").reorder("price_in_cent::decimal/strikethrough_price_in_cent asc").first(25).pluck(:id)
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
            # 避免切换地址商品不正确
            current_user.reset_redis_store_shopping_cart_items
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
            # UpdateRedisShoppingCartItemsJob.perform_later(current_user, current_postal_code, current_suburb, current_store_id)
            response_success
          else
            response_record_error(cart_item)
          end
        end
      end
    end
  end
end
