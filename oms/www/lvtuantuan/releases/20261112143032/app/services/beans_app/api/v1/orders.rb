# frozen_string_literal: true

module BeansApp
  class API::V1::Orders < ::API
    namespace :orders, desc: "订单API" do
      helpers do
        def end_of_association_chain
          if params[:status].present?
            resource_class.visible.public_send(params[:status])
          else
            resource_class.visible
          end
        end

        def includes
          [:user, :store, :coupon, :order_invoice, :gift_coupon_template, order_items: [:effective_after_sales_order_items, :comments]]
        end

        def generate_receiver_properties
          if params[:delivery_type] == "self_pick"
            @self_pick_up = MagicBean::SelfPickUp.find_by(id: params[:self_pick_up_id])
            return {} if !@self_pick_up && params[:is_preview]

            response_error I18n.t("grape.orders.missing_self_pick_up")  unless @self_pick_up
            receiver_tel_number = params[:receiver_mobile].presence || params[:receiver_tel_number].presence
            # 预览订单不验证收货人信息
            response_error I18n.t("grape.orders.missing_recipient_info") if !params[:is_preview] && [params[:receiver_first_name], params[:receiver_last_name], receiver_tel_number].select(&:blank?).present?

            @self_pick_up.to_order_json(params[:receiver_first_name], params[:receiver_last_name], receiver_tel_number)
          else
            @address = current_user.pick_address params[:address_id]
            @address&.to_order_json
          end
        end

        def check_receiver_address(order, address)
          return if address.blank?

          if order.delivery_type.in?(["express", "merchant_delivery"]) && !address.valid?
            I18n.t("grape.orders.invalid_address")
          end
        end

        def check_gift_card_coupon(order)
          return [nil, nil] if order.ae_drop_shipper || (params[:gift_card_coupon_code].blank? && params[:gift_card_pin_code].blank?)

          error_message = nil
          gift_card_coupon = MagicBean::GiftCardCoupon.find_by(code: params[:gift_card_coupon_code], pin_code: params[:gift_card_pin_code])
          if gift_card_coupon
            if gift_card_coupon.store_ids.present? && !order.store_id.in?(gift_card_coupon.store_ids)
              error_message = I18n.t("grape.orders.gift_card_can_not_use")
            else
              if gift_card_coupon.pending?
                error_message = I18n.t("grape.orders.gift_card_insufficient_blance") if gift_card_coupon.unused_amount_in_cent < params[:gift_card_amount_in_cent].to_i
                order.gift_card_coupon = gift_card_coupon
                order.gift_card_amount_in_cent = params[:gift_card_amount_in_cent]
              else
                gift_card_coupon = nil
                error_message = I18n.t("grape.orders.gift_card_used_or_expired")
              end
            end
          else
            error_message = I18n.t("grape.orders.gift_card_not_correct")
          end

          [gift_card_coupon, error_message]
        end

        def check_delivery_date_expired(order)
          if params[:delivery_date].present?
            if order.merchant_delivery?
              # 子单在设置值的时候会检查是否有母单，所以子单不检查配送日期
              return true if order.is_child
              available_delivery_time = order.send :available_delivery_time
              merchant_delivery_address_limit = order.send :merchant_delivery_address_limit
              if available_delivery_time.present?
                period_setting = order.delivery_time_period_setting

                if available_delivery_time.limited_by_orders_limit_every_day
                  distinct_address_count = order.send :merchant_distinct_address_count, params[:delivery_date].to_date

                  # 检查全站配置的额度
                  wday_valid = params[:delivery_date].to_date.wday.to_s.in?(available_delivery_time.weekdays)

                  if wday_valid && (merchant_delivery_address_limit.zero? || distinct_address_count < merchant_delivery_address_limit)
                    order.next_day_delivery = false
                  else
                    I18n.t("grape.orders.delivery_is_full", delivery_date: params[:delivery_date])
                    response_error I18n.t("grape.orders.delivery_is_full", delivery_date: params[:delivery_date])
                  end
                elsif available_delivery_time.specific_orders_limit_active? && period_setting.order_address_limit_every_day.positive?
                  distinct_address_count = order.send :delivery_time_period_distinct_address_count, params[:delivery_date].to_date, params[:delivery_time_period_setting_id]
                  response_error I18n.t("grape.orders.delivery_for_perfer_time_is_full", prefer_time: period_setting.prefer_time) if period_setting.order_address_limit_every_day <= distinct_address_count
                end
              end
              available_delivery_dates = order.send :available_delivery_dates
              response_error I18n.t("grape.orders.delivery_date_expired") unless available_delivery_dates.any? { |date| date[:date].to_s == params[:delivery_date] }
            elsif order.self_pick?
              self_pick_orders_limit = order.send :self_pick_orders_limit
              if self_pick_orders_limit.positive?
                orders_count = order.send :self_pick_date_orders_count, params[:delivery_date].to_date
                response_error I18n.t("grape.orders.delivery_is_full", delivery_date: params[:delivery_date]) if orders_count >= self_pick_orders_limit
              end
            end
          end
        end

        # 月饼赠品每人限领一盒
        def check_gift_sku(store_id)
          sku = MagicBean::StockKeepingUnit.find_by(no: "ht51278", store_id: store_id)
          return if (params[:gift_sku_ids] || []).exclude?(sku&.id)
          # 检查是否已经领过增品，未支付的订单也需要检查
          if MagicBean::Order.where(store_id: store_id).trade_not_close.where("EXISTS (SELECT FROM json_array_elements(orders.gifts_properties) gift_element WHERE (gift_element->>'stock_keeping_unit_id')::int = #{sku.id})").where(user_id: current_user.id).exists?
            I18n.t("grape.orders.already_get_this_gift")
          end
        end

        def check_same_day_delivery_date_expired(order)
          if params[:delivery_date].present?
            if order.merchant_delivery?
              available_delivery_time = order.send :available_delivery_time
              merchant_delivery_address_limit = order.send :merchant_delivery_address_limit
              if available_delivery_time.present?
                if available_delivery_time.limited_by_orders_limit_every_day && merchant_delivery_address_limit.positive?
                  distinct_address_count = order.send :merchant_distinct_address_count, params[:delivery_date].to_date
                  response_error I18n.t("grape.orders.delivery_is_full", delivery_date: params[:delivery_date]) if merchant_delivery_address_limit <= distinct_address_count
                end

                if order.same_day_delivery_time_period.present?
                  period = order.same_day_delivery_time_period
                  address_count_limit = period.address_count_limit.to_i
                  same_day_period_distinct_address_count = order.send :same_day_period_merchant_distinct_address_count, params[:delivery_date].to_date, period.id
                  response_error I18n.t("grape.orders.delivery_for_perfer_time_is_full", prefer_time: params[:prefer_time]) if address_count_limit.positive? && same_day_period_distinct_address_count >= period.address_count_limit
                end
              end

              available_delivery_dates = order.send :available_delivery_dates
              response_error I18n.t("grape.orders.delivery_date_expired") unless available_delivery_dates.any? { |date| date[:date].to_s == params[:delivery_date] }
            elsif order.self_pick?
              self_pick_orders_limit = order.send :self_pick_orders_limit
              if self_pick_orders_limit.positive?
                orders_count = order.send :self_pick_date_orders_count, params[:delivery_date].to_date
                response_error I18n.t("grape.orders.delivery_is_full", delivery_date: params[:delivery_date]) if orders_count >= self_pick_orders_limit
              end
            end
          end
        end

        def check_skus_stock(order)
          error_messages = []
          order.order_items.each do |item|
            sku = item.stock_keeping_unit
            error_messages << " #{sku.human_title} #{I18n.t("grape.orders.insufficient_inventory")}" if sku.quantity < item.quantity
          end
          error_messages.join("; ")
        end

        def promo_order_items(store_id)
          return [] unless params[:promo_code]

          @promo_code = MagicBean::PromoCode.active.find_by(code: params[:promo_code]&.strip)
          return [] unless @promo_code

          return [nil, I18n.t("grape.orders.promo_code_no_balance")] if !@promo_code.can_use?(current_user.id)

          promo_skus = @promo_code.promo_stock_keeping_units
          return [nil, I18n.t("grape.orders.different_stores_promo_code")] if promo_skus.present? && promo_skus.first.stock_keeping_unit.store_id != store_id.to_i

          order_item_json =
            promo_skus.map do |psku|
              psku.stock_keeping_unit
                .to_order_item_json(psku.quantity, psku.price_in_cent).first
                .merge({ promo_code_id: @promo_code.id })
            end
          [order_item_json, nil]
        end

        def active_time_limited_promotion_prices(sku_ids)
          prices = {}
          MagicBean::TimeLimitedPromotionPrice.active.where(store_id: current_store_id, stock_keeping_unit_id: sku_ids).each { |price| prices[price.stock_keeping_unit_id.to_s] = price.price_in_cent }
          prices
        end

        def check_order_creation_disabled(order)
          config = order.store.site_config
          if config.order_creation_disabled
            MagicBean::MultiLangConfig.config(config.store_id, I18n.locale, :admin).order_creation_api_disabled_tips
          end
        end

        def check_payment_in_progress!
          response_error I18n.t("grape.orders.repeat_payment") if resource.payment_in_progress
        end

        # 限制单用户并发下单
        def check_user_concurrent_order_limit!
          return if params[:is_preview]
          limit = Rails.cache.redis.get("#{MagicBean::User::PLACE_ORDER_LIMIT_KEY}_#{current_user.id}").to_i
          response_error I18n.t("grape.orders.concurrent_order_limit") if limit.positive?
          Rails.cache.redis.set("#{MagicBean::User::PLACE_ORDER_LIMIT_KEY}_#{current_user.id}", limit + 1, ex: 10.seconds)
        end

        # 跨境购订单金额限制$1000
        def check_ae_order_amount(order)
          if order.ae_drop_shipper && (order.payment_in_cent - order.ae_gst_amount_in_cent) > 100000
            I18n.t("grape.orders.ae_order_amount_limit")
          end
        end

        def release_user_concurrent_order_limit!
          return if params[:is_preview]
          Rails.cache.redis.del("#{MagicBean::User::PLACE_ORDER_LIMIT_KEY}_#{current_user.id}")
        end

        def set_order_time_zone(order)
          Time.zone = order.order_store_time_zone
        end

        def reset_ae_drop_shipper_params(ae_drop_shipper)
          if ae_drop_shipper
            params[:cost_integral] = 0
            params[:coupon_code] = nil
            params[:promo_code] = nil
            params[:gift_activity_id] = nil
            params[:gift_price_gradient] = nil
            params[:gift_coupon_template_id] = nil
            params[:gift_sku_ids] = nil
          end
        end

        # 检查是否为小程序渠道，如果是则不允许下单
        def check_mini_program_channel!
          response_error(I18n.t("grape.orders.mini_program_not_allowed")) if ebest_channel == "mini_program"
        end

        params :self_pick_order_params do
          optional :self_pick_up_id, type: Integer, desc: "自提点ID"
          optional :receiver_first_name, type: String, desc: "自提订单联系人名"
          optional :receiver_last_name, type: String, desc: "自提订单联系人姓"
          optional :receiver_mobile, type: String, desc: "自提订单联系号码（等其他地方都改好后弃用）"
          optional :receiver_tel_number, type: String, desc: "自提订单联系号码"
          # all_or_none_of :self_pick_up_id, :receiver_first_name, :receiver_last_name, :receiver_mobile
        end

        params :merchant_delivery_params do
          optional :same_day_delivery_time_period_id, type: Integer, desc: "当日达订单才需要传"
          optional :delivery_date, type: String, desc: "派送日期"
          optional :prefer_time, type: String, desc: "派送时间段"
          optional :delivery_time_period_setting_id, type: Integer, desc: "派送时间段设置ID"
          all_or_none_of :prefer_time, :delivery_date
        end

        params :virtual_delivery_params do
          optional :receiver_first_name, type: String, desc: "联系人名"
          optional :receiver_last_name, type: String, desc: "联系人姓"
          optional :receiver_tel_number, type: String, desc: "联系电话"
          optional :receiver_email, type: String, desc: "联系人邮箱"
        end
      end

      desc "订单列表", {
        success: API::Entities::SimpleOrder,
        is_array: true
      }
      paginate
      params do
        optional :status, type: String, values: [
          "wait_buyer_pay",
          "wait_seller_send_goods",
          "wait_buyer_confirm_goods"
        ], desc: "订单的状态"
        optional :status_in, type: Array[String],
          coerce_with: ->(val) { val.split(",").map(&:strip) },
          desc: "多状态查询",
          documentation: { param_type: "query" }
        optional :type_eq, type: String, values: ["MagicBean::NormalOrder", "MagicBean::GrouponOrder", ""], default: "", desc: "空字符串：返回所有订单"
        optional :delivery_type_eq, values: -> { ::MagicBean::Order.delivery_types.keys }
        optional :no_or_order_items_title_or_order_items_properties_text_cont_any, type: String, desc: "订单商品标题或订单号"
      end
      get do
        authorize_and_response_collection
      end

      desc "购物车创建订单", {
        success: API::Entities::Order
      }
      params do
        requires :shopping_cart_item_ids, type: Array[Integer],
          coerce_with: ->(val) { val.split(",").map(&:to_i) },
          desc: "购物车中的商品条目ID"
        optional :delivery_type, type: String, desc: "配送方式, 可选项为所有产品都可用的配送方式", values: -> { ::MagicBean::Order.delivery_types.keys }
        optional :address_id, type: Integer, desc: "地址 ID"
        optional :buyer_message, type: String, desc: "买家留言"
        optional :is_preview, type: Boolean, desc: "订单预览"
        optional :coupon_code, type: String, desc: "优惠券码"
        optional :gift_card_pin_code, type: String, desc: "礼品券pin码"
        optional :gift_card_coupon_code, type: String, desc: "礼品券码"
        optional :gift_card_amount_in_cent, type: Integer, desc: "使用礼品券金额"
        optional :scene_code, type: String, desc: "小程序场景值"
        optional :cost_integral, type: Integer, desc: "使用积分"
        use :self_pick_order_params
        use :merchant_delivery_params
        optional :authority_to_leave, type: Grape::API::Boolean, desc: "authority to leave"
        optional :deliver_to_door, type: Grape::API::Boolean, desc: "是否送货上楼"
        optional :promo_code, type: String, desc: "Promo Code"
        optional :gift_activity_id, type: Integer, desc: "赠品活动 ID"
        optional :gift_price_gradient, type: Float, desc: "所选赠品梯度金额"
        optional :gift_sku_ids, type: Array[Integer], desc: "赠品 SKU"
        optional :gift_coupon_template_id, type: Integer, desc: "赠品优惠券 ID"
        optional :free_shipping_code, type: String, desc: "免邮码"
      end
      post do
        # 检查是否为小程序，如果是则不允许下单
        check_mini_program_channel!
        
        # 1. 获取收货地址
        receiver_properties = generate_receiver_properties

        # 2. 获取购物车中的 items
        shopping_cart_items = current_user.shopping_cart_items.includes(stock_keeping_unit: :item).where(
          id: params[:shopping_cart_item_ids]
        )

        # 4. 创建订单
        if shopping_cart_items.any?
          store_ids = shopping_cart_items.map(&:store_id).uniq
          response_error I18n.t("grape.orders.different_stores_skus") if store_ids.size > 1

          ae_drop_shippers = shopping_cart_items.map { |cart_item| cart_item.stock_keeping_unit.ae_drop_shipper }.uniq
          response_error I18n.t("grape.orders.different_ae_drop_shipper_skus") if ae_drop_shippers.size > 1
          order_ae_drop_shipper = ae_drop_shippers.first

          # 跨境购订单不支持优惠券、金币、礼品卡、满赠、优惠池、promo_code、限时优惠，限时优惠在配置源头限制
          reset_ae_drop_shipper_params(order_ae_drop_shipper)

          promo_items, promo_skus_error_message = promo_order_items(store_ids.first)

          active_prices = active_time_limited_promotion_prices(shopping_cart_items.map(&:stock_keeping_unit_id))

          items_order_json, new_user_item_errors = [], []

          order_live_top = false

          shopping_cart_items.each do |item|
            # 只要有一个商品是置顶，则认为该订单为置顶订单
            order_live_top = true if !order_live_top && item.live_top
            item_json = item.to_order_item_json(active_prices["#{item.stock_keeping_unit_id}"], current_user)
            items_order_json << item_json[0]
            new_user_item_errors << item_json[1] if item_json[1]
          end

          order_live_top = false if params[:delivery_type].to_s.in?(["express", "virtual_delivery"])

          order_items_attributes = [
            *items_order_json,
            *(promo_items || [])
          ]
          order = current_user.normal_orders.new(
            is_direct_buy: false,
            receiver_properties: receiver_properties,
            buyer_message: params[:buyer_message],
            order_items_attributes: order_items_attributes,
            scene_code: params[:scene_code],
            cost_integral: params[:cost_integral].presence,
            is_preview: params[:is_preview],
            delivery_type: params[:delivery_type],
            self_pick_up_id: params[:self_pick_up_id],
            authority_to_leave: params[:authority_to_leave],
            deliver_to_door: params[:deliver_to_door],
            delivery_date: params[:delivery_date],
            prefer_time: params[:prefer_time],
            channel: ebest_channel,
            current_postal_code: current_postal_code,
            current_suburb: current_suburb,
            store_id: store_ids.first,
            gift_activity_id: params[:gift_activity_id],
            gift_sku_ids: params[:gift_sku_ids] || [],
            gift_price_gradient: params[:gift_price_gradient],
            gift_coupon_template_id: params[:gift_coupon_template_id],
            promo_code: @promo_code,
            live_top: order_live_top,
            free_shipping_code: params[:free_shipping_code]&.strip,
            ae_drop_shipper: order_ae_drop_shipper,
            delivery_time_period_setting_id: params[:delivery_time_period_setting_id],
            address_housing_type: @address&.housing_type
          )

          set_order_time_zone(order)

          # 查出订单所有满足条件的优惠池
          order.active_pools = order_ae_drop_shipper ? {} : MagicBean::PreferentialPool.active_for_order(order)
          order.calculate_payment_amount if order.active_pools["discount"].present? || order.active_pools["reduction"].present?

          coupon = order.use_coupon(params[:coupon_code], params[:is_preview])
          order.coupon = coupon if coupon

          gift_card_coupon, gift_card_error_message = check_gift_card_coupon(order)

          skus_stock_error_message = check_skus_stock(order)

          gift_sku_error_message = check_gift_sku(order.store_id)

          order_creation_error_message = check_order_creation_disabled(order)

          receiver_address_error_message = check_receiver_address(order, @address)

          order.calculate_payment_amount if coupon || gift_card_coupon

          ae_order_amount_error_message = check_ae_order_amount(order)

          authorize! :create, order

          if params[:is_preview]
            order.validate
            order.errors.add(:base, order_creation_error_message) if order_creation_error_message
            order.errors.add(:base, gift_card_error_message) if gift_card_error_message
            order.errors.add(:base, promo_skus_error_message) if promo_skus_error_message
            order.errors.add(:base, skus_stock_error_message) if skus_stock_error_message.present?
            order.errors.add(:base, gift_sku_error_message) if gift_sku_error_message.present?
            order.errors.add(:base, new_user_item_errors.join("，")) if new_user_item_errors.present?
            order.errors.add(:base, receiver_address_error_message) if receiver_address_error_message.present?
            order.errors.add(:base, ae_order_amount_error_message) if ae_order_amount_error_message.present?
            order.check_order_items_real_price_and_display_price
            order.preview_gift_activity
            present :order, order, with: API::Entities::PreviewOrder,
                    address: @address,
                    coupon: coupon,
                    gift_card_coupon: gift_card_coupon
            present :coupons, current_user.usable_coupons_for(order, ebest_channel), with: API::Entities::Coupon
          else
            response_error new_user_item_errors.join("，") if new_user_item_errors.present?
            response_error(order_creation_error_message) if order_creation_error_message
            response_error(gift_card_error_message) if gift_card_error_message
            response_error(skus_stock_error_message) if skus_stock_error_message.present?
            response_error(gift_sku_error_message) if gift_sku_error_message.present?
            response_error(promo_skus_error_message) if promo_skus_error_message.present?
            response_error(receiver_address_error_message) if receiver_address_error_message.present?
            response_error(ae_order_amount_error_message) if ae_order_amount_error_message.present?
            check_delivery_date_expired(order) if order.merchant_delivery? || order.self_pick?
            
            # 限制单用户并发下单
            check_user_concurrent_order_limit!
            
            order.send :counter_to_redis

            result = order.save

            # 订单创建后释放并发下单限制
            release_user_concurrent_order_limit!

            if result
              unless promo_skus_error_message
                @promo_code&.increment(:used_count) && @promo_code.save
              end
              present order, with: API::Entities::Order
            else
              order.send :release_counter_from_redis
              response_record_error(order)
            end
          end
        else
          response_error I18n.t("grape.orders.shopping_cart_empty")
        end
      rescue ActiveRecord::RecordInvalid => e
        release_user_concurrent_order_limit!
        order.send :release_counter_from_redis
        order.recalculate_payment_amount
        error!({ order: order, error_message: e.message }, 400)
      rescue ActiveRecord::RecordNotUnique
        release_user_concurrent_order_limit!
        order.send :release_counter_from_redis
        error!({ order: order, error_message: I18n.t("error.order.coupon_already_used") }, 400)
      end

      desc "立即购买", {
        success: API::Entities::Order
      }
      params do
        requires :stock_keeping_unit_id, type: Integer, desc: "商品 ID"
        requires :quantity, type: Integer, desc: "商品数量"
        optional :delivery_type, type: String, desc: "配送方式, 可选项为产品配送方式", values: -> { ::MagicBean::Order.delivery_types.keys }
        optional :address_id, type: Integer, desc: "地址 ID"
        optional :buyer_message, type: String, desc: "买家留言"
        optional :is_preview, type: Boolean, desc: "订单预览"
        optional :coupon_code, type: String, desc: "优惠券码"
        optional :gift_card_pin_code, type: String, desc: "礼品券pin码"
        optional :gift_card_coupon_code, type: String, desc: "礼品券码"
        optional :gift_card_amount_in_cent, type: Integer, desc: "使用礼品券金额"
        optional :scene_code, type: String, desc: "小程序场景值"
        optional :cost_integral, type: Integer, desc: "使用积分"
        use :self_pick_order_params
        use :merchant_delivery_params
        optional :authority_to_leave, type: Grape::API::Boolean, desc: "authority to leave"
        optional :deliver_to_door, type: Grape::API::Boolean, desc: "是否送货上楼"
        optional :promo_code, type: String, desc: "Promo Code"
        optional :gift_activity_id, type: Integer, desc: "赠品活动 ID"
        optional :gift_price_gradient, type: Float, desc: "所选赠品梯度金额"
        optional :gift_sku_ids, type: Array[Integer], desc: "赠品 SKU"
        optional :gift_coupon_template_id, type: Integer, desc: "赠品优惠券 ID"
        optional :source_page_name, type: String, values: MagicBean::OrderItem.source_page_names.keys, desc: "页面名"
        # optional :source_custom_list_id, type: Integer,  desc: "自定义页面id（source额外参数传 source_extra_hash，hash类型，grape没法只定义空hash就在这里说明了）"
        optional :live_top, type: Boolean, desc: "直播间置顶并免邮"
        optional :free_shipping_code, type: String, desc: "免邮码"
      end
      post "direct_buy" do
        # 检查是否为小程序，如果是则不允许下单
        check_mini_program_channel!
        
        stock_keeping_unit = MagicBean::StockKeepingUnit.find(params[:stock_keeping_unit_id])
        response_error(I18n.t("error.order.please_select_not_virtual_item")) if stock_keeping_unit.item.is_virtual
        response_error(I18n.t("error.order.please_select_not_gift_only_item")) if stock_keeping_unit.gift_only

        # 1. 获取收货地址
        receiver_properties = generate_receiver_properties

        order_ae_drop_shipper = stock_keeping_unit.ae_drop_shipper
        reset_ae_drop_shipper_params(order_ae_drop_shipper)

        promo_items, promo_skus_error_message = promo_order_items(stock_keeping_unit.store_id)

        active_prices = active_time_limited_promotion_prices(stock_keeping_unit.id)

        order_live_top = params[:live_top].nil? ? false : params[:live_top]
        order_live_top = false if params[:delivery_type].to_s.in?(["express", "virtual_delivery"])

        source_custom_list_id = params[:source_custom_list_id] == "fixed" ? nil : params[:source_custom_list_id]
        sku_order_item_json, new_user_item_error = stock_keeping_unit.to_order_item_json(params[:quantity], active_prices["#{stock_keeping_unit.id}"], nil, false, ebest_channel, params[:source_page_name], source_custom_list_id, params[:source_extra_hash], current_user, order_live_top)

        # 4. 创建订单
        order = current_user.normal_orders.new(
          is_direct_buy: true,
          receiver_properties: receiver_properties,
          buyer_message: params[:buyer_message],
          order_items_attributes: [
            sku_order_item_json,
            *(promo_items || [])
          ],
          scene_code: params[:scene_code],
          cost_integral: params[:cost_integral].presence,
          is_preview: params[:is_preview],
          delivery_type: params[:delivery_type],
          self_pick_up_id: params[:self_pick_up_id],
          authority_to_leave: params[:authority_to_leave],
          deliver_to_door: params[:deliver_to_door],
          delivery_date: params[:delivery_date],
          prefer_time: params[:prefer_time],
          channel: ebest_channel,
          current_postal_code: current_postal_code,
          current_suburb: current_suburb,
          store_id: stock_keeping_unit.store_id,
          gift_activity_id: params[:gift_activity_id],
          gift_sku_ids: params[:gift_sku_ids] || [],
          gift_price_gradient: params[:gift_price_gradient],
          gift_coupon_template_id: params[:gift_coupon_template_id],
          promo_code: @promo_code,
          live_top: order_live_top,
          free_shipping_code: params[:free_shipping_code]&.strip,
          ae_drop_shipper: order_ae_drop_shipper,
          delivery_time_period_setting_id: params[:delivery_time_period_setting_id],
          address_housing_type: @address&.housing_type
        )

        set_order_time_zone(order)

        # 查出订单所有满足条件的优惠池
        order.active_pools = order_ae_drop_shipper ? {} : MagicBean::PreferentialPool.active_for_order(order)
        order.calculate_payment_amount if order.active_pools["discount"].present? || order.active_pools["reduction"].present?

        coupon = order.use_coupon(params[:coupon_code], params[:is_preview])
        order.coupon = coupon if coupon

        gift_card_coupon, gift_card_error_message = check_gift_card_coupon(order)
        skus_stock_error_message = check_skus_stock(order)
        gift_sku_error_message = check_gift_sku(order.store_id)
        order_creation_error_message = check_order_creation_disabled(order)
        receiver_address_error_message = check_receiver_address(order, @address)

        order.calculate_payment_amount if coupon || gift_card_coupon

        ae_order_amount_error_message = check_ae_order_amount(order)

        authorize! :create, order

        if params[:is_preview]
          order.validate
          order.errors.add(:base, order_creation_error_message) if order_creation_error_message
          order.errors.add(:base, gift_card_error_message) if gift_card_error_message
          order.errors.add(:base, promo_skus_error_message) if promo_skus_error_message
          order.errors.add(:base, skus_stock_error_message) if skus_stock_error_message.present?
          order.errors.add(:base, gift_sku_error_message) if gift_sku_error_message.present?
          order.errors.add(:base, new_user_item_error) if new_user_item_error.present?
          order.errors.add(:base, receiver_address_error_message) if receiver_address_error_message.present?
          order.errors.add(:base, ae_order_amount_error_message) if ae_order_amount_error_message.present?

          order.check_order_items_real_price_and_display_price
          order.preview_gift_activity

          present :order, order, with: API::Entities::PreviewOrder,
                  address: @address,
                  coupon: coupon,
                  gift_card_coupon: gift_card_coupon
          present :coupons, current_user.usable_coupons_for(order, ebest_channel), with: API::Entities::Coupon
        else
          response_error(new_user_item_error) if new_user_item_error.present?
          response_error(order_creation_error_message) if order_creation_error_message
          response_error(gift_card_error_message) if gift_card_error_message
          response_error(skus_stock_error_message) if skus_stock_error_message.present?
          response_error(gift_sku_error_message) if gift_sku_error_message.present?
          response_error(promo_skus_error_message) if promo_skus_error_message.present?
          response_error(receiver_address_error_message) if receiver_address_error_message.present?
          check_delivery_date_expired(order) if order.merchant_delivery? || order.self_pick?
          response_error(ae_order_amount_error_message) if ae_order_amount_error_message.present?
          
          # 限制单用户并发下单
          check_user_concurrent_order_limit!

          order.send :counter_to_redis

          result = order.save

          # 订单创建后释放并发下单限制
          release_user_concurrent_order_limit!

          if result
            unless promo_skus_error_message
              @promo_code&.increment(:used_count) && @promo_code.save
            end
            present order, with: API::Entities::Order
          else
            order.send :release_counter_from_redis
            response_record_error(order)
          end
        end
      rescue ActiveRecord::RecordInvalid => e
        release_user_concurrent_order_limit!
        order.send :release_counter_from_redis
        order.recalculate_payment_amount
        error!({ order: order, error_message: e.message }, 400)
      rescue ActiveRecord::RecordNotUnique
        release_user_concurrent_order_limit!
        order.send :release_counter_from_redis
        error!({ order: order, error_message: I18n.t("error.order.coupon_already_used") }, 400)
      end

      desc "虚拟商品立即购买", {
        success: API::Entities::Order
      }
      params do
        requires :stock_keeping_unit_id, type: Integer, desc: "商品 ID"
        requires :quantity, type: Integer, desc: "商品数量"
        optional :delivery_type, type: String, desc: "配送方式, 可选项为产品配送方式", values: -> { ::MagicBean::Order.delivery_types.keys }
        optional :address_id, type: Integer, desc: "地址 ID"
        optional :buyer_message, type: String, desc: "买家留言"
        optional :is_preview, type: Boolean, desc: "订单预览"
        optional :coupon_code, type: String, desc: "优惠券码"
        optional :gift_card_pin_code, type: String, desc: "礼品券pin码"
        optional :gift_card_coupon_code, type: String, desc: "礼品券码"
        optional :gift_card_amount_in_cent, type: Integer, desc: "使用礼品券金额"
        optional :scene_code, type: String, desc: "小程序场景值"
        optional :cost_integral, type: Integer, desc: "使用积分"
        use :virtual_delivery_params
        optional :source_page_name, type: String, values: MagicBean::ShoppingCartItem.source_page_names.keys, desc: "页面名"
        # optional :source_custom_list_id, type: Integer,  desc: "自定义页面id（source额外参数传 source_extra_hash，hash类型，grape没法只定义空hash就在这里说明了）"
      end
      post "virtual_direct_buy" do
        # 检查是否为小程序，如果是则不允许下单
        check_mini_program_channel!
        
        stock_keeping_unit = MagicBean::StockKeepingUnit.find(params[:stock_keeping_unit_id])
        response_error(I18n.t("grape.orders.select_virtual_order")) unless stock_keeping_unit.item.is_virtual

        response_error(I18n.t("grape.orders.missing_recipient_info")) if !params[:is_preview] && [params[:receiver_first_name], params[:receiver_last_name], params[:receiver_tel_number], params[:receiver_email]].any?(&:blank?)

        # 1. 获取收货地址
        receiver_properties = generate_receiver_properties || {}

        receiver_properties.merge!(
          {
            first_name: params[:receiver_first_name],
            last_name: params[:receiver_last_name],
            tel_number: params[:receiver_tel_number],
            email: params[:receiver_email],
          }.as_json)

        order_ae_drop_shipper = stock_keeping_unit.ae_drop_shipper
        reset_ae_drop_shipper_params(order_ae_drop_shipper)

        active_prices = active_time_limited_promotion_prices(stock_keeping_unit.id)

        source_custom_list_id = params[:source_custom_list_id] == "fixed" ? nil : params[:source_custom_list_id]
        sku_order_item_json, new_user_item_error = stock_keeping_unit.to_order_item_json(params[:quantity], active_prices["#{stock_keeping_unit.id}"], nil, false, ebest_channel, params[:source_page_name], source_custom_list_id, params[:source_extra_hash], current_user)

        order = current_user.virtual_orders.new(
          is_direct_buy: true,
          order_items_attributes: [
            sku_order_item_json,
          ],
          scene_code: params[:scene_code],
          buyer_message: params[:buyer_message],
          cost_integral: params[:cost_integral].presence,
          is_preview: params[:is_preview],
          delivery_type: :virtual_delivery,
          channel: ebest_channel,
          current_postal_code: current_postal_code,
          current_suburb: current_suburb,
          store_id: stock_keeping_unit.store_id,
          promo_code: @promo_code,
          receiver_properties: receiver_properties,
          ae_drop_shipper: order_ae_drop_shipper,
          address_housing_type: @address&.housing_type
        )

        set_order_time_zone(order)

        # 查出订单所有满足条件的优惠池
        order.active_pools = order_ae_drop_shipper ? {} : MagicBean::PreferentialPool.active_for_order(order)
        order.calculate_payment_amount if order.active_pools["discount"].present? || order.active_pools["reduction"].present?

        coupon = order.use_coupon(params[:coupon_code], params[:is_preview])
        order.coupon = coupon if coupon

        gift_card_coupon, gift_card_error_message = check_gift_card_coupon(order)
        skus_stock_error_message = check_skus_stock(order)
        gift_sku_error_message = check_gift_sku(order.store_id)
        order_creation_error_message = check_order_creation_disabled(order)
        receiver_address_error_message = check_receiver_address(order, @address)

        order.calculate_payment_amount if coupon || gift_card_coupon

        authorize! :create, order

        if params[:is_preview]
          order.validate
          order.errors.add(:base, order_creation_error_message) if order_creation_error_message
          order.errors.add(:base, gift_card_error_message) if gift_card_error_message
          order.errors.add(:base, skus_stock_error_message) if skus_stock_error_message.present?
          order.errors.add(:base, gift_sku_error_message) if gift_sku_error_message.present?
          order.errors.add(:base, new_user_item_error) if new_user_item_error.present?
          order.errors.add(:base, receiver_address_error_message) if receiver_address_error_message.present?

          order.check_order_items_real_price_and_display_price
          order.preview_gift_activity

          present :order, order, with: API::Entities::PreviewOrder,
                  address: @address,
                  coupon: coupon,
                  gift_card_coupon: gift_card_coupon
          present :coupons, current_user.usable_coupons_for(order, ebest_channel), with: API::Entities::Coupon
        else
          response_error new_user_item_error if new_user_item_error.present?
          response_error(order_creation_error_message) if order_creation_error_message
          response_error(gift_card_error_message) if gift_card_error_message
          response_error(skus_stock_error_message) if skus_stock_error_message.present?
          response_error(gift_sku_error_message) if gift_sku_error_message.present?
          response_error(receiver_address_error_message) if receiver_address_error_message.present?

          check_user_concurrent_order_limit!

          result = order.save

          # 订单创建后释放并发下单限制
          release_user_concurrent_order_limit!

          if result
            present order, with: API::Entities::Order
          else
            response_record_error(order)
          end
        end
      rescue ActiveRecord::RecordInvalid => e
        release_user_concurrent_order_limit!
        order.recalculate_payment_amount
        error!({ order: order, error_message: e.message }, 400)
      rescue ActiveRecord::RecordNotUnique
        release_user_concurrent_order_limit!
        error!({ order: order, error_message: I18n.t("error.order.coupon_already_used") }, 400)
      end

      desc "拍卖商品创建订单/立即购买", {
        success: API::Entities::Order
      }
      params do
        use :virtual_delivery_params
        requires :is_direct_buy, type: Grape::API::Boolean, desc: "是否直接购买，用户从拍卖详情直接购买时传 true；拍卖正常结束支付传 false"
        optional :auction_activity_participation_id, type: Integer, desc: "拍卖活动参与记录 ID"
        optional :auction_activity_id, type: Integer, desc: "拍卖活动 ID，用户从拍卖详情直接购买时需传此值"
        optional :address_id, type: Integer, desc: "地址 ID"
        optional :buyer_message, type: String, desc: "买家留言"
        optional :is_preview, type: Boolean, desc: "订单预览"
        optional :coupon_code, type: String, desc: "优惠券码"
        optional :gift_card_pin_code, type: String, desc: "礼品券pin码"
        optional :gift_card_coupon_code, type: String, desc: "礼品券码"
        optional :gift_card_amount_in_cent, type: Integer, desc: "使用礼品券金额"
        optional :cost_integral, type: Integer, desc: "使用积分"
        exactly_one_of :auction_activity_participation_id, :auction_activity_id
      end
      post "auction_buy" do
        # 检查是否为小程序，如果是则不允许下单
        check_mini_program_channel!
        
        is_direct_buy = (params[:is_direct_buy] == true)

        if is_direct_buy
          current_auction_activity = MagicBean::Auction::Activity.bidding.find(params[:auction_activity_id])

          response_error(I18n.t("grape.orders.can_not_pay")) if current_auction_activity.directly_purchase_price_in_cent.blank?

          current_auction_activity.refresh_sku_price(is_direct_buy)
          stock_keeping_unit = current_auction_activity.stock_keeping_unit
        else
          auction_activity_participation = current_user.auction_activity_participations.find(params[:auction_activity_participation_id])
          response_error(I18n.t("grape.orders.can_not_pay")) unless auction_activity_participation.paying_state?

          current_auction_activity = auction_activity_participation.auction_activity
          current_auction_activity.refresh_sku_price(is_direct_buy)
          stock_keeping_unit = current_auction_activity.stock_keeping_unit
        end

        response_error(I18n.t("grape.orders.can_not_create_duplicated_order")) if MagicBean::OrderItem.exists?(stock_keeping_unit_id: stock_keeping_unit.id)
        response_error(I18n.t("grape.orders.receiver_info_is_required")) if !params[:is_preview] && [params[:receiver_first_name], params[:receiver_last_name], params[:receiver_tel_number], params[:receiver_email]].any?(&:blank?)

        # 1. 获取收货地址
        receiver_properties = generate_receiver_properties || {}

        receiver_properties.merge!(
          {
            first_name: params[:receiver_first_name],
            last_name: params[:receiver_last_name],
            tel_number: params[:receiver_tel_number],
            email: params[:receiver_email],
          }.as_json
        )

        order_ae_drop_shipper = stock_keeping_unit.ae_drop_shipper
        reset_ae_drop_shipper_params(order_ae_drop_shipper)

        sku_order_item_json, new_user_item_error = stock_keeping_unit.to_order_item_json(1, stock_keeping_unit.price_in_cent, nil, false, ebest_channel, nil, nil, nil, current_user)

        order = current_user.auction_orders.new(
          is_direct_buy: is_direct_buy,
          order_items_attributes: [
            sku_order_item_json,
          ],
          cost_integral: params[:cost_integral].presence,
          is_preview: params[:is_preview],
          delivery_type: :virtual_delivery,
          channel: ebest_channel,
          current_postal_code: current_postal_code,
          current_suburb: current_suburb,
          store_id: stock_keeping_unit.store_id,
          receiver_properties: receiver_properties,
          ae_drop_shipper: order_ae_drop_shipper,
          address_housing_type: @address&.housing_type
        )

        set_order_time_zone(order)

        coupon = order.use_coupon(params[:coupon_code], params[:is_preview])
        order.coupon = coupon if coupon

        gift_card_coupon, gift_card_error_message = check_gift_card_coupon(order)
        order_creation_error_message = check_order_creation_disabled(order)
        receiver_address_error_message = check_receiver_address(order, @address)

        order.calculate_payment_amount if coupon || gift_card_coupon

        authorize! :create, order

        if params[:is_preview]
          order.validate
          order.errors.add(:base, order_creation_error_message) if order_creation_error_message
          order.errors.add(:base, gift_card_error_message) if gift_card_error_message
          order.errors.add(:base, receiver_address_error_message) if receiver_address_error_message.present?

          order.check_order_items_real_price_and_display_price
          order.preview_gift_activity

          present :order, order, with: API::Entities::PreviewOrder,
                  address: @address,
                  coupon: coupon,
                  gift_card_coupon: gift_card_coupon
          present :coupons, current_user.usable_coupons_for(order, ebest_channel), with: API::Entities::Coupon
        else
          response_error(order_creation_error_message) if order_creation_error_message
          response_error(gift_card_error_message) if gift_card_error_message
          response_error(receiver_address_error_message) if receiver_address_error_message.present?

          ActiveRecord::Base.transaction do
            order.save!
            current_auction_activity.update_attribute :order_id, order.id

            if is_direct_buy
              winning_participation = current_user.auction_activity_participations.find_or_initialize_by(
                auction_activity_id: current_auction_activity.id, store_id: current_auction_activity.store_id
              )
              winning_participation.update!(amount_in_cent: stock_keeping_unit.price_in_cent, auction_order_id: order.id)
              winning_participation.direct_buy!
              current_auction_activity.direct_buy!
            end
          end

          if order.valid?
            present order, with: API::Entities::Order
          else
            response_record_error(order)
          end
        end
      rescue ActiveRecord::RecordInvalid => e
        order.recalculate_payment_amount
        error!({ order: order, error_message: e.message }, 400)
      rescue ActiveRecord::RecordNotUnique
        error!({ order: order, error_message: I18n.t("error.order.coupon_already_used") }, 400)
      end

      desc "拼团购买", {
        success: API::Entities::Order
      }
      params do
        requires :groupon_activity_id, type: Integer, desc: "拼团活动 ID"
        optional :sku_groupon_id, type: Integer, desc: "SKU拼团 ID, 拼团类型为SKU时，该字段必填"
        optional :groupon_id, type: Integer, desc: "拼团 ID"
        requires :stock_keeping_unit_id, type: Integer, desc: "商品 ID"
        optional :delivery_type, type: String, desc: "配送方式, 可选项为产品配送方式", values: -> { ::MagicBean::Order.delivery_types.keys }
        requires :quantity, type: Integer, desc: "商品数量"
        optional :address_id, type: Integer, desc: "地址 ID"
        optional :buyer_message, type: String, desc: "买家留言"
        optional :is_preview, type: Boolean, desc: "订单预览"
        optional :scene_code, type: String, desc: "小程序场景值"
        optional :gift_card_pin_code, type: String, desc: "礼品券pin码"
        optional :gift_card_coupon_code, type: String, desc: "礼品券码"
        optional :gift_card_amount_in_cent, type: Integer, desc: "使用礼品券金额"
        use :self_pick_order_params
        use :merchant_delivery_params
        optional :authority_to_leave, type: Grape::API::Boolean, desc: "authority to leave"
        optional :deliver_to_door, type: Grape::API::Boolean, desc: "是否送货上楼"
        optional :source_page_name, type: String, values: MagicBean::ShoppingCartItem.source_page_names.keys, desc: "页面名"
        # optional :source_custom_list_id, type: Integer,  desc: "自定义页面id（source额外参数传 source_extra_hash，hash类型，grape没法只定义空hash就在这里说明了）"
        optional :free_shipping_code, type: String, desc: "免邮码"
      end
      post "groupon_buy" do
        # 检查是否为小程序，如果是则不允许下单
        check_mini_program_channel!
        
        stock_keeping_unit = MagicBean::StockKeepingUnit.find(params[:stock_keeping_unit_id])
        groupon_activity = MagicBean::GrouponActivity.find(params[:groupon_activity_id])
        response_error I18n.t("grape.orders.groupon_cannot_create") if groupon_activity.is_a?(MagicBean::BigGrouponActivity) && params[:groupon_id].blank?
        sku_groupon = groupon_activity.sku_groupons.enabled.find(params[:sku_groupon_id]) if params[:sku_groupon_id].present?
        groupon = groupon_activity.waiting_groupons.find(params[:groupon_id]) if params[:groupon_id].to_i.positive?

        response_error I18n.t("grape.orders.groupon_product_not_match") if groupon_activity.item_id != stock_keeping_unit.item_id
        response_error I18n.t("grape.orders.groupon_is_full") if groupon && !groupon.waiting?
        response_error I18n.t("grape.orders.sku_groupon_blank") if groupon_activity.sku? && sku_groupon.blank?
        response_error I18n.t("grape.orders.sku_groupon_not_match") if sku_groupon && sku_groupon.stock_keeping_unit != stock_keeping_unit

        # 确定订单项的价格
        item_price = groupon_activity.item? ? groupon_activity.price_in_cent : sku_groupon.price_in_cent

        # 获取收货地址
        receiver_properties = generate_receiver_properties

        order_ae_drop_shipper = stock_keeping_unit.ae_drop_shipper
        reset_ae_drop_shipper_params(order_ae_drop_shipper)

        source_custom_list_id = params[:source_custom_list_id] == "fixed" ? nil : params[:source_custom_list_id]
        sku_order_item_json, new_user_item_error = stock_keeping_unit.to_order_item_json(params[:quantity], item_price, nil, false, ebest_channel, params[:source_page_name], source_custom_list_id, params[:source_extra_hash], current_user)

        # 创建订单
        order = current_user.groupon_orders.new(
          is_direct_buy: true,
          receiver_properties: receiver_properties,
          buyer_message: params[:buyer_message],
          order_items_attributes: [
            sku_order_item_json
          ],
          groupon_activity: groupon_activity,
          sku_groupon_id: sku_groupon&.id,
          groupon_id: groupon&.id,
          scene_code: params[:scene_code],
          is_preview: params[:is_preview],
          delivery_type: params[:delivery_type],
          self_pick_up_id: params[:self_pick_up_id],
          authority_to_leave: params[:authority_to_leave],
          deliver_to_door: params[:deliver_to_door],
          delivery_date: params[:delivery_date],
          prefer_time: params[:prefer_time],
          channel: ebest_channel,
          current_postal_code: current_postal_code,
          current_suburb: current_suburb,
          store_id: stock_keeping_unit.store_id,
          free_shipping_code: params[:free_shipping_code]&.strip,
          ae_drop_shipper: order_ae_drop_shipper,
          delivery_time_period_setting_id: params[:delivery_time_period_setting_id],
          address_housing_type: @address&.housing_type
        )

        set_order_time_zone(order)

        gift_card_coupon, gift_card_error_message = check_gift_card_coupon(order)
        skus_stock_error_message = check_skus_stock(order)
        gift_sku_error_message = check_gift_sku(order.store_id)
        order_creation_error_message = check_order_creation_disabled(order)
        receiver_address_error_message = check_receiver_address(order, @address)

        order.calculate_payment_amount if gift_card_coupon

        authorize! :create, order

        if params[:is_preview]
          order.validate
          order.errors.add(:base, order_creation_error_message) if order_creation_error_message
          order.errors.add(:base, gift_card_error_message) if gift_card_error_message
          order.errors.add(:base, skus_stock_error_message) if skus_stock_error_message.present?
          order.errors.add(:base, gift_sku_error_message) if gift_sku_error_message.present?
          order.errors.add(:base, new_user_item_error) if new_user_item_error.present?
          order.errors.add(:base, receiver_address_error_message) if receiver_address_error_message.present?

          order.check_order_items_real_price_and_display_price

          present :order, order, with: API::Entities::PreviewOrder, address: @address, gift_card_coupon: gift_card_coupon
        else
          response_error new_user_item_error if new_user_item_error.present?
          response_error(order_creation_error_message) if order_creation_error_message
          response_error(gift_card_error_message) if gift_card_error_message
          response_error(skus_stock_error_message) if skus_stock_error_message.present?
          response_error(gift_sku_error_message) if gift_sku_error_message.present?
          response_error(receiver_address_error_message) if receiver_address_error_message.present?
          check_delivery_date_expired(order) if order.merchant_delivery? || order.self_pick?

          # 订单创建前限制并发下单
          check_user_concurrent_order_limit!

          order.send :counter_to_redis

          result = order.save
          # 订单创建后释放并发下单限制
          release_user_concurrent_order_limit!

          if result
            present order, with: API::Entities::Order
          else
            order.send :release_counter_from_redis
            response_record_error(order)
          end
        end
      rescue ActiveRecord::RecordInvalid => e
        release_user_concurrent_order_limit!
        order.send :release_counter_from_redis
        order.recalculate_payment_amount
        error!({ order: order, error_message: e.message }, 400)
      end

      desc "当日达购物车创建订单", {
        success: API::Entities::Order
      }
      params do
        requires :same_day_delivery_cart_item_ids, type: Array[Integer],
                 coerce_with: ->(val) { val.split(",").map(&:to_i) },
                 desc: "当日达购物车中的商品条目ID"
        optional :delivery_type, type: String, desc: "配送方式, 可选项为所有产品都可用的配送方式", values: -> { ::MagicBean::Order.delivery_types.keys }
        optional :address_id, type: Integer, desc: "地址 ID"
        optional :buyer_message, type: String, desc: "买家留言"
        optional :is_preview, type: Boolean, desc: "订单预览"
        optional :coupon_code, type: String, desc: "优惠券码"
        optional :gift_card_pin_code, type: String, desc: "礼品券pin码"
        optional :gift_card_coupon_code, type: String, desc: "礼品券码"
        optional :gift_card_amount_in_cent, type: Integer, desc: "使用礼品券金额"
        optional :scene_code, type: String, desc: "小程序场景值"
        optional :cost_integral, type: Integer, desc: "使用积分"
        use :self_pick_order_params
        use :merchant_delivery_params
        optional :authority_to_leave, type: Grape::API::Boolean, desc: "authority to leave"
        optional :deliver_to_door, type: Grape::API::Boolean, desc: "是否送货上楼"
        optional :promo_code, type: String, desc: "Promo Code"
        optional :gift_activity_id, type: Integer, desc: "赠品活动 ID"
        optional :gift_price_gradient, type: Float, desc: "所选赠品梯度金额"
        optional :gift_sku_ids, type: Array[Integer], desc: "赠品 SKU"
        optional :gift_coupon_template_id, type: Integer, desc: "赠品优惠券 ID"
      end
      post "same_day_delivery" do
        # 检查是否为小程序，如果是则不允许下单
        check_mini_program_channel!
        
        # 1. 获取收货地址
        receiver_properties = generate_receiver_properties

        # 2. 获取购物车中的 items
        shopping_cart_items = current_user.same_day_delivery_cart_items.includes(stock_keeping_unit: :item).where(
          id: params[:same_day_delivery_cart_item_ids]
        )

        # 4. 创建订单
        if shopping_cart_items.any?
          store_ids = shopping_cart_items.map(&:store_id).uniq
          response_error I18n.t("grape.orders.different_stores_skus") if store_ids.size > 1

          ae_drop_shippers = shopping_cart_items.map { |cart_item| cart_item.stock_keeping_unit.ae_drop_shipper }.uniq
          response_error I18n.t("grape.orders.different_ae_drop_shipper_skus") if ae_drop_shippers.size > 1

          order_ae_drop_shipper = ae_drop_shippers.first
          reset_ae_drop_shipper_params(order_ae_drop_shipper)

          promo_items, promo_skus_error_message = promo_order_items(store_ids.first)

          active_prices = active_time_limited_promotion_prices(shopping_cart_items.map(&:stock_keeping_unit_id))

          items_order_json, new_user_item_errors = [], []
          shopping_cart_items.each do |item|
            item_json = item.to_order_item_json(active_prices["#{item.stock_keeping_unit_id}"], current_user)
            items_order_json << item_json[0]
            new_user_item_errors << item_json[1] if item_json[1]
          end

          order_items_attributes = [
            *items_order_json,
            *(promo_items || [])
          ]
          order = current_user.same_day_delivery_orders.new(
            is_direct_buy: false,
            receiver_properties: receiver_properties,
            buyer_message: params[:buyer_message],
            order_items_attributes: order_items_attributes,
            scene_code: params[:scene_code],
            cost_integral: params[:cost_integral].presence,
            is_preview: params[:is_preview],
            delivery_type: params[:delivery_type],
            self_pick_up_id: params[:self_pick_up_id],
            authority_to_leave: params[:authority_to_leave],
            deliver_to_door: params[:deliver_to_door],
            same_day_delivery_time_period_id: params[:same_day_delivery_time_period_id],
            delivery_date: params[:delivery_date],
            prefer_time: params[:prefer_time],
            channel: ebest_channel,
            current_postal_code: current_postal_code,
            current_suburb: current_suburb,
            store_id: store_ids.first,
            gift_activity_id: params[:gift_activity_id],
            gift_sku_ids: params[:gift_sku_ids] || [],
            gift_price_gradient: params[:gift_price_gradient],
            gift_coupon_template_id: params[:gift_coupon_template_id],
            promo_code: @promo_code,
            ae_drop_shipper: order_ae_drop_shipper,
            address_housing_type: @address&.housing_type
          )

          set_order_time_zone(order)

          # 查出订单所有满足条件的优惠池
          order.active_pools = order_ae_drop_shipper ? {} : MagicBean::PreferentialPool.active_for_order(order)
          order.calculate_payment_amount if order.active_pools["discount"].present? || order.active_pools["reduction"].present?

          coupon = order.use_coupon(params[:coupon_code], params[:is_preview])
          order.coupon = coupon if coupon

          gift_card_coupon, gift_card_error_message = check_gift_card_coupon(order)

          skus_stock_error_message = check_skus_stock(order)

          gift_sku_error_message = check_gift_sku(order.store_id)

          order_creation_error_message = check_order_creation_disabled(order)

          receiver_address_error_message = check_receiver_address(order, @address)

          order.calculate_payment_amount if coupon || gift_card_coupon

          authorize! :create, order

          if params[:is_preview]
            order.validate
            order.errors.add(:base, order_creation_error_message) if order_creation_error_message
            order.errors.add(:base, gift_card_error_message) if gift_card_error_message
            order.errors.add(:base, promo_skus_error_message) if promo_skus_error_message
            order.errors.add(:base, skus_stock_error_message) if skus_stock_error_message.present?
            order.errors.add(:base, gift_sku_error_message) if gift_sku_error_message.present?
            order.errors.add(:base, new_user_item_errors.join("，")) if new_user_item_errors.present?
            order.errors.add(:base, receiver_address_error_message) if receiver_address_error_message.present?

            order.check_order_items_real_price_and_display_price
            order.preview_gift_activity

            present :order, order, with: API::Entities::PreviewOrder,
                    address: @address,
                    coupon: coupon,
                    gift_card_coupon: gift_card_coupon
            present :coupons, current_user.usable_coupons_for(order, ebest_channel), with: API::Entities::Coupon
          else
            response_error new_user_item_errors.join("，") if new_user_item_errors.present?
            response_error(order_creation_error_message) if order_creation_error_message
            response_error(gift_card_error_message) if gift_card_error_message
            response_error(skus_stock_error_message) if skus_stock_error_message.present?
            response_error(gift_sku_error_message) if gift_sku_error_message.present?
            response_error(promo_skus_error_message) if promo_skus_error_message.present?
            response_error(receiver_address_error_message) if receiver_address_error_message.present?
            check_same_day_delivery_date_expired(order) if order.merchant_delivery? || order.self_pick?

            # 订单创建前限制并发下单
            check_user_concurrent_order_limit!

            order.send :counter_to_redis
            
            result = order.save
            # 订单创建后释放并发下单限制
            release_user_concurrent_order_limit!

            if result
              unless promo_skus_error_message
                @promo_code&.increment(:used_count) && @promo_code.save
              end
              present order, with: API::Entities::Order
            else
              order.send :release_counter_from_redis
              response_record_error(order)
            end
          end
        else
          response_error I18n.t("grape.orders.shopping_cart_empty")
        end
      rescue ActiveRecord::RecordInvalid => e
        release_user_concurrent_order_limit!
        order.send :release_counter_from_redis
        order.recalculate_payment_amount
        error!({ order: order, error_message: e.message }, 400)
      rescue ActiveRecord::RecordNotUnique
        release_user_concurrent_order_limit!
        order.send :release_counter_from_redis
        error!({ order: order, error_message: I18n.t("error.order.coupon_already_used") }, 400)
      end

      desc "当日达立即购买", {
        success: API::Entities::Order
      }
      params do
        requires :stock_keeping_unit_id, type: Integer, desc: "商品 ID"
        requires :quantity, type: Integer, desc: "商品数量"
        optional :delivery_type, type: String, desc: "配送方式, 当日达只可选自提和自派", values: -> { ::MagicBean::Order.delivery_types.keys }
        optional :address_id, type: Integer, desc: "地址 ID"
        optional :buyer_message, type: String, desc: "买家留言"
        optional :is_preview, type: Boolean, desc: "订单预览"
        optional :coupon_code, type: String, desc: "优惠券码"
        optional :gift_card_pin_code, type: String, desc: "礼品券pin码"
        optional :gift_card_coupon_code, type: String, desc: "礼品券码"
        optional :gift_card_amount_in_cent, type: Integer, desc: "使用礼品券金额"
        optional :scene_code, type: String, desc: "小程序场景值"
        optional :cost_integral, type: Integer, desc: "使用积分"
        use :self_pick_order_params
        use :merchant_delivery_params
        optional :authority_to_leave, type: Grape::API::Boolean, desc: "authority to leave"
        optional :deliver_to_door, type: Grape::API::Boolean, desc: "是否送货上楼"
        optional :promo_code, type: String, desc: "Promo Code"
        optional :gift_activity_id, type: Integer, desc: "赠品活动 ID"
        optional :gift_price_gradient, type: Float, desc: "所选赠品梯度金额"
        optional :gift_sku_ids, type: Array[Integer], desc: "赠品 SKU"
        optional :gift_coupon_template_id, type: Integer, desc: "赠品优惠券 ID"
        optional :source_page_name, type: String, values: MagicBean::OrderItem.source_page_names.keys, desc: "页面名"
        # optional :source_custom_list_id, type: Integer,  desc: "自定义页面id（source额外参数传 source_extra_hash，hash类型，grape没法只定义空hash就在这里说明了）"
      end
      post "same_day_delivery_direct_buy" do
        # 检查是否为小程序，如果是则不允许下单
        check_mini_program_channel!
        
        stock_keeping_unit = MagicBean::StockKeepingUnit.find(params[:stock_keeping_unit_id])
        response_error(I18n.t("grape.orders.select_none_virtual_order")) if stock_keeping_unit.item.is_virtual

        # 1. 获取收货地址
        receiver_properties = generate_receiver_properties

        order_ae_drop_shipper = stock_keeping_unit.ae_drop_shipper
        reset_ae_drop_shipper_params(order_ae_drop_shipper)

        promo_items, promo_skus_error_message = promo_order_items(stock_keeping_unit.store_id)

        active_prices = active_time_limited_promotion_prices(stock_keeping_unit.id)

        source_custom_list_id = params[:source_custom_list_id] == "fixed" ? nil : params[:source_custom_list_id]
        sku_order_item_json, new_user_item_error = stock_keeping_unit.to_order_item_json(params[:quantity], active_prices["#{stock_keeping_unit.id}"], nil, false, ebest_channel, params[:source_page_name], source_custom_list_id, params[:source_extra_hash], current_user)

        # 4. 创建订单
        order = current_user.same_day_delivery_orders.new(
          is_direct_buy: true,
          receiver_properties: receiver_properties,
          buyer_message: params[:buyer_message],
          order_items_attributes: [
            sku_order_item_json,
            *(promo_items || [])
          ],
          scene_code: params[:scene_code],
          cost_integral: params[:cost_integral].presence,
          is_preview: params[:is_preview],
          delivery_type: params[:delivery_type],
          self_pick_up_id: params[:self_pick_up_id],
          authority_to_leave: params[:authority_to_leave],
          deliver_to_door: params[:deliver_to_door],
          same_day_delivery_time_period_id: params[:same_day_delivery_time_period_id],
          delivery_date: params[:delivery_date],
          prefer_time: params[:prefer_time],
          channel: ebest_channel,
          current_postal_code: current_postal_code,
          current_suburb: current_suburb,
          store_id: stock_keeping_unit.store_id,
          gift_activity_id: params[:gift_activity_id],
          gift_sku_ids: params[:gift_sku_ids] || [],
          gift_price_gradient: params[:gift_price_gradient],
          gift_coupon_template_id: params[:gift_coupon_template_id],
          promo_code: @promo_code,
          ae_drop_shipper: order_ae_drop_shipper,
          address_housing_type: @address&.housing_type
        )

        set_order_time_zone(order)

        # 查出订单所有满足条件的优惠池
        order.active_pools = order_ae_drop_shipper ? {} : MagicBean::PreferentialPool.active_for_order(order)
        order.calculate_payment_amount if order.active_pools["discount"].present? || order.active_pools["reduction"].present?

        coupon = order.use_coupon(params[:coupon_code], params[:is_preview])
        order.coupon = coupon if coupon

        gift_card_coupon, gift_card_error_message = check_gift_card_coupon(order)
        skus_stock_error_message = check_skus_stock(order)
        gift_sku_error_message = check_gift_sku(order.store_id)
        order_creation_error_message = check_order_creation_disabled(order)
        receiver_address_error_message = check_receiver_address(order, @address)

        order.calculate_payment_amount if coupon || gift_card_coupon

        authorize! :create, order

        if params[:is_preview]
          order.validate
          order.errors.add(:base, order_creation_error_message) if order_creation_error_message
          order.errors.add(:base, gift_card_error_message) if gift_card_error_message
          order.errors.add(:base, promo_skus_error_message) if promo_skus_error_message
          order.errors.add(:base, skus_stock_error_message) if skus_stock_error_message.present?
          order.errors.add(:base, gift_sku_error_message) if gift_sku_error_message.present?
          order.errors.add(:base, new_user_item_error) if new_user_item_error.present?
          order.errors.add(:base, receiver_address_error_message) if receiver_address_error_message.present?

          order.check_order_items_real_price_and_display_price
          order.preview_gift_activity

          present :order, order, with: API::Entities::PreviewOrder,
                  address: @address,
                  coupon: coupon,
                  gift_card_coupon: gift_card_coupon
          present :coupons, current_user.usable_coupons_for(order, ebest_channel), with: API::Entities::Coupon
        else
          response_error new_user_item_error if new_user_item_error.present?
          response_error(order_creation_error_message) if order_creation_error_message
          response_error(gift_card_error_message) if gift_card_error_message
          response_error(skus_stock_error_message) if skus_stock_error_message.present?
          response_error(gift_sku_error_message) if gift_sku_error_message.present?
          response_error(promo_skus_error_message) if promo_skus_error_message.present?
          response_error(receiver_address_error_message) if receiver_address_error_message.present?
          check_same_day_delivery_date_expired(order) if order.merchant_delivery? || order.self_pick?

          # 订单创建前限制并发下单
          check_user_concurrent_order_limit!

          order.send :counter_to_redis

          result = order.save
          # 订单创建后释放并发下单限制
          release_user_concurrent_order_limit!

          if result
            unless promo_skus_error_message
              @promo_code&.increment(:used_count) && @promo_code.save
            end
            present order, with: API::Entities::Order
          else
            order.send :release_counter_from_redis
            response_record_error(order)
          end
        end
      rescue ActiveRecord::RecordInvalid => e
        release_user_concurrent_order_limit!
        order.send :release_counter_from_redis
        order.recalculate_payment_amount
        error!({ order: order, error_message: e.message }, 400)
      rescue ActiveRecord::RecordNotUnique
        release_user_concurrent_order_limit!
        order.send :release_counter_from_redis
        error!({ order: order, error_message: I18n.t("error.order.coupon_already_used") }, 400)
      end

      desc "WEB CBA session（英文网站现在没在用，该接口证书也没更新，暂时不用）"
      params do
        requires :validation_url, type: String
        requires :platform, type: String, values: ["mobile", "desktop"]
      end
      get :web_apple_pay_session do
        session = ApplePay::Payment.merchant_validation(params[:validation_url], params[:platform])

        if session.present?
          session
        else
          response_error
        end
      end

      route_param :id do
        desc "订单详情", {
          success: API::Entities::Order
        }
        params do
          optional :need_response, type: Grape::API::Boolean, desc: "需要返回银联支付response"
        end
        get do
          authorize_and_response_resource(params: { need_response: params[:need_response] })
        end

        desc "取消订单", {
          success: API::Entities::Order
        }
        put "close" do
          authorize_and_run_member_action(:close, { method: :perform_aasm_event }, :close)
        end

        desc "确认收货", {
          success: API::Entities::Order
        }
        put "confirm_goods" do
          authorize_and_run_member_action(:confirm_goods, { method: :perform_aasm_event }, :receive)
        end

        desc "申请退款", {
          success: API::Entities::SuccessfulResult
        }
        params do
          optional :apply_reason, type: String, desc: "退款原因"
        end
        put "apply_refund" do
          authorize! :apply_refund, resource

          if resource.refundable? && resource.may_apply? && resource.apply!
            resource.update(apply_reason: params[:apply_reason] || "买家要求直接退款")
            response_success
          else
            response_error(I18n.t("grape.orders.cannot_refund"))
          end
        end

        desc "获取微信支付参数", {
          detail: <<-NOTES.strip_heredoc
            ```json
            {
              "appId": "",
              "package": "prepay_id=wx3015162450394482e7a10b052399580378",
              "nonceStr": "qfMB0RjwTl7BNC3L",
              "timeStamp": "1535613384",
              "signType": "MD5",
              "paySign": "162B8FC6F32B957C91D101AC09F44BA8"
            }
            ```
          NOTES
        }
        post "request_payment" do
          authorize! :request_wechat_payment, resource

          if resource.wait_buyer_pay?
            check_payment_in_progress!
            begin
              resource.ip_address = ip_address
              result = resource.request_wechat_payment(ebest_channel)
            rescue RestClient::Exceptions::Timeout
              response_error(I18n.t("grape.connection.timeout"))
            end
            if result[:status] == "success"
              present result[:data]
            else
              response_error(result[:msg])
            end
          else
            response_error(I18n.t("grape.orders.order_expired"))
          end
        end

        desc "Stripe支付"
        params do
          requires :card, type: Hash do
            requires :type, type: String, values: ["vm", "unionpay"], desc: "卡类型"
            requires :number, type: String, desc: "卡号"
            requires :exp_year, type: String, desc: "卡过期年份"
            requires :exp_month, type: String, desc: "卡过期月份"
            requires :cvc, type: String, desc: "卡CVC"
          end
          optional :email, type: String, desc: "邮箱"
        end

        post "request_stripe_payment" do
          if resource.wait_buyer_pay?
            check_payment_in_progress!
            success, message = resource.request_stripe_payment(params[:card], params[:email], ebest_channel)
            if success
              response_success
            else
              response_error(message)
            end
          else
            response_error(I18n.t("grape.orders.order_expired"))
          end
        end

        desc "Stripe 3DS支付凭证"
        params do
          requires :payment_type, type: String, values: ["credit_card", "apple_pay", "google_pay"], desc: "卡类型"
        end
        post "request_stripe_session" do
          if resource.wait_buyer_pay?
            check_payment_in_progress!

            check_result = resource.check_stripe_order_paid_by_order_no(ebest_channel)
            response_error(check_result[:error_msg]) if check_result[:error_msg].present?

            begin
              # 为了增强支付安全性，需要关联用户信息
              user_full_name = resource.user_member.full_name&.strip
              user_mobile = resource.user_member.mobile&.strip
              user_email = resource.user_member.email&.strip

              query_sql = "phone:'#{resource.user_member.mobile}'"
              query_sql += " and name:'#{user_full_name}'" if user_full_name.present?
              query_sql += " and email:'#{user_email}'" if user_email.present?

              customer = ::Stripe::Customer.search({ query: query_sql }).data&.first
              unless customer
                customer = ::Stripe::Customer.create(
                  name: user_full_name,
                  phone: user_mobile,
                  email: user_email,
                  shipping: {
                    address: {
                      city: resource.receiver_city_name,
                      country: "Australia",
                      postal_code: resource.receiver_postal_code,
                      state: resource.receiver_province_name,
                      line1: resource.receiver_pure_detail_info,
                      line2: resource.receiver_unit_number
                    },
                    name: resource.receiver_name,
                    phone: resource.receiver_tel_number
                  }
                )
              end

              # App用户保存支付信息需要用到
              ephemeral_key = ::Stripe::EphemeralKey.create({
                customer: customer["id"],
              }, {stripe_version: "2023-08-16"})

              payment_intent = ::Stripe::PaymentIntent.create({
                amount: resource.send("stripe_#{params[:payment_type]}_payment_in_cent"), # 这里是分
                currency: "aud",
                payment_method_types: ["card"],
                description: "Charge #{resource.no}",
                customer: customer.id,
                # setup_future_usage: "on_session",
                metadata: {
                  order_no: resource.no,
                  type: params[:payment_type]
                },
              })
              
              resource.update_columns(
                stripe_transaction_id: payment_intent["id"],
                credit_card_payment_in_cent: resource.send("stripe_#{params[:payment_type]}_payment_in_cent"),
                credit_card_service_percentage: resource.no_transaction_fee? ? 0 : resource.send("stripe_#{params[:payment_type]}_service_percentage")
              )

              { payment_intent: payment_intent["client_secret"], ephemeral_key: ephemeral_key["secret"], customer: customer["id"] }
            rescue => e
              response_error(e.message)
            end
          else
            response_error(I18n.t("grape.orders.order_expired"))
          end
        end

        desc "Commweb Payment"
        params do
          requires :card, type: Hash do
            requires :type, type: String, values: ["vm", "unionpay"], desc: "卡类型"
            requires :number, type: String, desc: "卡号"
            requires :exp_year, type: String, desc: "卡过期年份"
            requires :exp_month, type: String, desc: "卡过期月份"
            requires :cvc, type: String, desc: "卡CVC"
          end
          optional :email, type: String, desc: "邮箱"
        end

        post "request_commweb_payment" do
          response_error(I18n.t("grape.orders.order_expired")) unless resource.wait_buyer_pay?
          check_payment_in_progress!

          resource.ip_address = ip_address

          success, message =
            if params[:card][:type].eql?("vm")
              resource.request_commweb_payment(params[:card], params[:email], ebest_channel)
            else
              resource.request_union_pay_payment(ebest_channel, params[:card])
            end

          if success
            response_success
          else
            response_error(message)
          end
        end

        desc "Commweb Payment With Session"
        params do
          requires :session_id, type: String
        end
        post "pay_with_commweb_session" do
          response_error(I18n.t("grape.orders.order_expired")) unless resource.wait_buyer_pay?
          check_payment_in_progress!
          success, message = resource.pay_with_commeb_session(params[:session_id], ebest_channel)
          if success
            response_success
          else
            response_error(message)
          end
        end

        desc "Omipay支付凭证", {
          detail: <<-NOTES.strip_heredoc
        ```json
        {
          "order_no": "TR2004273512253006525",
          "order_string": "{\"partnerId\":\"334649281\",\"package\":\"Sign=WXPay\",\"prepayId\":\"wx27172228742422cb8b685eaa1618542000\",\"sign\":\"6E9CE12A57A6D7D2A25DF7402793C387\",\"timeStamp\":\"1587979349\",\"nonceStr\":\"18802ab58b29439f8c14f7ae20017bfa\"}",
          "error_msg": null,
          "msg": null,
          "success": true,
          "return_code": "SUCCESS"
        }
        ```
          NOTES
        }
        params do
          requires :platform, values: MagicBean::OmipayPayment::PLATFORMS
        end
        post :make_omipay_app_order do
          check_payment_in_progress!
          check_result = resource.check_omipay_order_paid_by_order_no("app")
          response_error(check_result[:error_msg]) if check_result[:error_msg].present?
          response = resource.make_omipay_app_order(params[:platform])
          if response["return_code"] == "SUCCESS"
            resource.update(omipay_transaction_id: response["order_no"], omipay_platform: params[:platform])
            response
          else
            response_error(response["error_msg"])
          end
        end

        desc "Supay支付凭证", {
          detail: <<-NOTES.strip_heredoc
        ```json
        {
          "status"=>"T",
          "message"=>nil,
          "data"=>
            {
              "result"=>true,
              "pay_info"=>"{\"appid\":\"wx79d7a20918ac064c\",\"noncestr\":\"4psY1nnUHDOwsCP0YSwOrKk0v4mHpROJ\",\"package\":\"Sign=WXPay\",\"partnerid\":\"554862491\",\"prepayid\":\"wx07181308732914bec4a93884de26880000\",\"sign\":\"9B0283E97872662F8502F270209FEE21906D8F2E0AD641584321863F14C0F12E\",\"timestamp\":\"1675764788\"}",
              "sign"=>"6916b9253160d8eda534b4df21dac971",
              "sign_type"=>"MD5"
            }
        }
        ```
          NOTES
        }
        params do
          requires :platform, values: MagicBean::SupayPayment::PLATFORMS
        end
        post :make_supay_app_order do
          check_payment_in_progress!
          check_result = resource.check_supay_order_paid_by_order_no("app")
          response_error(check_result[:error_msg]) if check_result[:error_msg].present?
          response = resource.make_supay_app_order(params[:platform])
          if response["status"] == "T"
            resource.update(supay_platform: params[:platform])
            response
          else
            response_error(response["message"])
          end
        end

        desc "银联Apple Pay, 需要传参paymentData"
        post :make_apple_pay do
          response_error(I18n.t("grape.orders.payment_data_incorrect")) if params[:paymentData].blank?
          response_error(I18n.t("grape.orders.not_support_unionpay_apple_pay")) if resource.apple_pay_service_percentage.negative?
          response_error(I18n.t("grape.orders.order_expired")) unless resource.wait_buyer_pay?
          check_payment_in_progress!

          token_attrs = JSON.parse(params[:paymentData].to_json)

          decrypt_token = JSON.parse ApplePay::Payment.decrypt_payment_token(token_attrs)

          card_data = decrypt_token["paymentData"]

          response_error(I18n.t("grape.orders.use_unionpay_card")) if card_data["emvData"].blank? || card_data["encryptedPINData"].blank?

          success, message = resource.request_unionpay_apple_pay_payment(decrypt_token["applicationPrimaryAccountNumber"], card_data)

          if success
            response_success
          else
            response_error(message)
          end
        end

        desc "CBA Apple Pay, 需要传参paymentData"
        post :make_cba_apple_pay do
          response_error(I18n.t("grape.orders.payment_data_incorrect")) if params[:paymentData].blank?
          response_error(I18n.t("grape.orders.not_support_vm_apple_pay")) if resource.cba_apple_pay_service_percentage.negative?
          response_error(I18n.t("grape.orders.order_expired")) unless resource.wait_buyer_pay?
          check_payment_in_progress!

          token_attrs = JSON.parse(params[:paymentData].to_json)

          decrypt_token = JSON.parse ApplePay::Payment.decrypt_payment_token(token_attrs)

          response_error(I18n.t("grape.orders.use_vm_amex_card")) if decrypt_token["paymentData"]["onlinePaymentCryptogram"].blank?

          success, message = resource.request_cba_apple_pay_payment(decrypt_token, ebest_channel)

          if success
            response_success
          else
            response_error(message)
          end
        end

        desc "CBA Google Pay, 需要传参paymentData"
        post :make_cba_google_pay do
          response_error(I18n.t("grape.orders.not_support_google_pay")) if resource.cba_google_pay_service_percentage.negative?
          response_error(I18n.t("grape.orders.payment_data_incorrect")) if params[:paymentData].blank?
          response_error(I18n.t("grape.orders.order_expired")) unless resource.wait_buyer_pay?
          check_payment_in_progress!

          payment_data = JSON.parse params[:paymentData]
          payment_token = payment_data["paymentMethodData"]["tokenizationData"]["token"]

          response_error(I18n.t("grape.orders.payment_data_incorrect")) if payment_token.blank?
          success, message = resource.request_cba_google_pay_payment(payment_token, ebest_channel)

          if success
            response_success
          else
            response_error(message)
          end
        end

        desc "批量创建评论", {
          success: API::Entities::SuccessfulResult,
          is_array: true
        }
        params do
          requires :comments, type: Array do
            requires :commentable_type, type: String, desc: "可评论资源类型", values: MagicBean::Comment::COMMENTABLE_TYPES
            requires :commentable_id, type: Integer, desc: "可评论资源 ID"
            requires :content, type: String, desc: "内容"
            optional :images, type: Array[String], desc: "图片"
          end
        end
        post "batch_comment" do
          authorize! :create, MagicBean::Comment

          comments = current_user.comments.create(params[:comments])

          if comments.map(&:errors).map(&:full_messages).flatten.empty?
            present resource, with: API::Entities::Order
          else
            response_error(comments.map { |object| object.errors.full_messages.join("，") }.join("；"))
          end
        end

        desc "订单商品添加到购物车", {
          success: API::Entities::ShoppingCartItem
        }
        post "shopping_cart_items" do
          authorize! :reorder, resource
          shopping_cart_items = if resource.type == "MagicBean::SameDayDeliveryOrder"
                                  current_user.same_day_delivery_cart.same_day_delivery_cart_items
                                else
                                  current_user.shopping_cart.shopping_cart_items
                                end
          reorder_shopping_cart_item_ids = []
          message = ""
          resource.order_items.includes(:stock_keeping_unit).each do |order_item|
            sku = order_item.stock_keeping_unit
            next if !sku.on_sale? || sku.quantity.zero?
            next if sku.item.is_virtual
            next if sku.gift_only
            next if is_new_user && sku.new_user_buy_quota_invalid?(sku.quantity, current_user)

            shopping_cart_item = shopping_cart_items.with_deleted.find_by(stock_keeping_unit_id: sku.id)

            if shopping_cart_item
              if shopping_cart_item.deleted?
                shopping_cart_item.quantity = [sku.quantity, order_item.quantity].min
                shopping_cart_item.deleted_at = nil
              else
                shopping_cart_item.quantity = [sku.quantity, shopping_cart_item.quantity + order_item.quantity].min
              end
            else
              shopping_cart_item = shopping_cart_items.new(quantity: [sku.quantity, order_item.quantity].min, stock_keeping_unit_id: sku.id)
            end

            shopping_cart_item.store_id = sku.store_id
            shopping_cart_item.source_page_name = "order_list"
            shopping_cart_item.source_extra_hash = { order_item_id: order_item.id }
            shopping_cart_item.source_channel = ebest_channel if ebest_channel
            shopping_cart_item.live_top = false unless resource.type == "MagicBean::SameDayDeliveryOrder"

            reorder_shopping_cart_item_ids << shopping_cart_item.id if shopping_cart_item.save
          end

          response_error(I18n.t("grape.orders.cannot_reorder")) if reorder_shopping_cart_item_ids.blank?

          message = I18n.t("grape.orders.products_cannot_reorder") if reorder_shopping_cart_item_ids.length != resource.order_items.length

          UpdateRedisShoppingCartItemsJob.perform_later(current_user, current_postal_code, current_suburb, current_store_id) unless resource.type == "MagicBean::SameDayDeliveryOrder"

          {
            message: message,
            data: {
              reorder_shopping_cart_item_ids: reorder_shopping_cart_item_ids.uniq
            }
          }
        end

        desc "用户删除订单", {
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
          authorize! :destroy, resource

          if resource.update(deleted_by_user_at: Time.current)
            response_success
          else
            response_record_error(resource)
          end
        end
      end
    end
  end
end
