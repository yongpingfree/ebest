# frozen_string_literal: true

module MagicBean
  class Ability
    include CanCan::Ability

    def initialize(user = nil)
      @user = user

      if @user
        send("#{user.class.name.demodulize.underscore}_abilities")
      else
        base_user_abilities
      end
    end

    def admin_user_abilities
      case @user.role
      when "super_admin"
        super_admin_abilities
      when "store_admin"
        store_admin_abilities
      when "store_assistant"
        store_assistant_abilities
      end

      # 活动页面目前只能查看
      cannot [:create, :update, :destroy], MagicBean::EventPage
      cannot [:create, :update, :destroy], MagicBean::EventFormRecord

      # 超管可以编辑所有
      # 非超管只能编辑自己
      cannot :destroy, MagicBean::AdminUser, id: @user.id # 管理员不能删除自己
      cannot :toggle_state, MagicBean::AdminUser do |resource|
        !@user.super_admin? || resource.id == @user.id
      end
      cannot :destroy, MagicBean::CustomPage, MagicBean::CustomPage.default do |resource|
        resource.default
      end
      # resource指新创建的管理员，@user指当前管理员，所以应该用@user来判断
      cannot :create, MagicBean::AdminUser do
        !@user.super_admin? && !@user.store_admin?
      end

      cannot :destroy, MagicBean::Item do |resource|
        resource.stock_keeping_units.map(&:order_items).flatten.any?
      end
    end

    def super_admin_abilities
      can :manage, :all
    end

    def store_admin_abilities
      store_base_abilities
      if @user.permissions.include?("admin_users")
        can :update, MagicBean::AdminUser, id: @user.id
        cannot :destroy, MagicBean::AdminUser
        # 分店管理员只能创建分店店员，但这里不好控制，在接口层做控制
        can [:create], MagicBean::AdminUser

        can :read, MagicBean::RoleTemplate
      end
    end

    def store_assistant_abilities
      store_base_abilities
    end

    def store_base_abilities
      can :read, MagicBean::Store, admin_user_stores: { admin_user_id: @user.id }
      can [:read, :create], MagicBean::Product
      can [:update], MagicBean::Product, ["store_id IN (?)", @user.store_ids] do |resource|
        resource.store_id.in?(@user.store_ids)
      end

      if @user.permissions.include?("items") || @user.permissions.include?("ae_items")
        can :manage, MagicBean::Item, ["items.store_id IN (?)", @user.store_ids] do |resource|
          resource.store_id.in?(@user.store_ids)
        end
        # 商品评论共用商品管理权限
        can :read, MagicBean::Comment
      end

      can :manage, MagicBean::FormItem, ["form_items.store_id IN (?)", @user.store_ids] do |resource|
        resource.store_id.in?(@user.store_ids)
      end if @user.permissions.include?("form_items")

      can :read, MagicBean::FormItemApplication, ["form_item_applications.store_id IN (?)", @user.store_ids] do |resource|
        resource.store_id.in?(@user.store_ids)
      end if @user.permissions.include?("form_item_applications")

      can :read, MagicBean::Brand if @user.permissions.include?("brands")

      can :read, MagicBean::HomepagePagingSetting if @user.permissions.include?("homepage_paging_settings")

      can :read, MagicBean::MinePageActivitySetting if @user.permissions.include?("mine_page_activity_settings")

      if @user.permissions.include?("categories") || @user.permissions.include?("ae_drop_shipper_categories")
        can :read, MagicBean::Category
        # 年龄验证跟分类强相关，共用一个权限
        can :manage, MagicBean::AgeVerification
      end

      can :read, MagicBean::DeliveryArea if @user.permissions.include?("delivery_areas")
      can :read, MagicBean::DeliveryTime if @user.permissions.include?("delivery_times")
      can :read, MagicBean::SameDayDeliveryTime if @user.permissions.include?("same_day_delivery_times")
      can :read, MagicBean::AuSuburb
      can :manage, MagicBean::AuSuburb if @user.permissions.include?("au_suburbs")
      can :read, MagicBean::QaAndGuarantee if @user.permissions.include?("qa_and_guarantees")
      can :read, MagicBean::SkuGroupon
      can :read, MagicBean::Logistic if @user.permissions.include?("logistics")
      can [:read, :create, :update], MagicBean::User if @user.permissions.include?("users")
      can :read, MagicBean::IntegralRecord
      can [:read, :update], MagicBean::UserSuggestion if @user.permissions.include?("user_suggestions")
      can [:read], MagicBean::UserRecommendedProduct if @user.permissions.include?("user_recommended_products")
      can :read, MagicBean::Member if @user.permissions.include?("members")
      can :read, MagicBean::EventPage if @user.permissions.include?("event_pages")
      can :manage, MagicBean::Page if @user.permissions.include?("pages")
      can :manage, MagicBean::ReportPage if @user.permissions.include?("report_pages")
      can :read, MagicBean::EventFormRecord if @user.permissions.include?("event_form_records")
      can :read, MagicBean::AdminUser, MagicBean::AdminUser.all do |resource|
        (resource.store_ids & @user.store_ids).present?
      end if @user.permissions.include?("admin_users")

      # can :manage, MagicBean::Item, store_id: @user.store_ids
      can :manage, MagicBean::StockKeepingUnit, ["stock_keeping_units.store_id IN (?)", @user.store_ids] do |resource|
        resource.store_id.in?(@user.store_ids)
      end if @user.permissions.include?("stock_keeping_units")
      can :manage, MagicBean::SkuProperty
      can :manage, MagicBean::SkuValue

      can :manage, MagicBean::Groupon, ["groupon.store_id IN (?)", @user.store_ids] do |resource|
        resource.store_id.in?(@user.store_ids)
      end

      can :manage, MagicBean::GrouponActivity, ["groupon_activities.store_id IN (?)", @user.store_ids] do |resource|
        resource.store_id.in?(@user.store_ids)
      end if @user.permissions.include?("groupon_activities")

      can :manage, MagicBean::GiftActivity, ["gift_activities.store_id IN (?)", @user.store_ids] do |resource|
        resource.store_id.in?(@user.store_ids)
      end if @user.permissions.include?("gift_activities")

      can :manage, MagicBean::Order, ["orders.store_id IN (?)", @user.store_ids] do |resource|
        resource.store_id.in?(@user.store_ids)
      end if @user.permissions.include?("normal_orders") || @user.permissions.include?("groupon_orders") || @user.permissions.include?("ae_orders")
      can :manage, MagicBean::AfterSale, ["after_sales.store_id IN (?)", @user.store_ids] do |resource|
        resource.store_id.in?(@user.store_ids)
      end if @user.permissions.include?("after_sales")

      can :manage, MagicBean::FreightTemplate, ["freight_templates.store_id IN (?)", @user.store_ids] do |resource|
        resource.store_id.in?(@user.store_ids)
      end if @user.permissions.include?("freight_templates")
      can :manage, MagicBean::DefaultFreightTemplate, ["freight_templates.store_id IN (?)", @user.store_ids] do |resource|
        resource.store_id.in?(@user.store_ids)
      end
      can :manage, MagicBean::ExceptionalFreightTemplate, ["freight_templates.store_id IN (?)", @user.store_ids] do |resource|
        resource.store_id.in?(@user.store_ids)
      end

      can :manage, MagicBean::CouponPackage, ["coupon_packages.store_id IN (?)", @user.store_ids] do |resource|
        resource.store_id.in?(@user.store_ids)
      end if @user.permissions.include?("coupon_packages")

      if @user.permissions.include?("coupon_templates")
        can :manage, MagicBean::CouponTemplate, ["coupon_templates.store_id IN (?)", @user.store_ids] do |resource|
          resource.store_id.in?(@user.store_ids)
        end
        can :manage, MagicBean::Coupon, ["coupons.store_id IN (?)", @user.store_ids] do |resource|
          resource.store_id.in?(@user.store_ids)
        end
      end

      can :manage, MagicBean::PreferentialPool, ["preferential_pools.store_id IN (?)", @user.store_ids] do |resource|
        resource.store_id.in?(@user.store_ids)
      end if @user.permissions.include?("preferential_pools")

      if @user.permissions.include?("gift_card_templates")
        can :read, MagicBean::GiftCardTemplate
        can [:create, :update], MagicBean::GiftCardTemplate, ["gift_card_templates.store_ids @> ARRAY[?]::integer[]", @user.store_ids] do |resource|
          (resource.store_ids & @user.store_ids).present?
        end
        can :manage, MagicBean::GiftCardCoupon
      end

      if @user.permissions.include?("promo_code_templates")
        can :read, MagicBean::PromoCodeTemplate
        can [:create, :update], MagicBean::PromoCodeTemplate, ["promo_code_templates.store_id IN (?)", @user.store_ids] do |resource|
          resource.store_id.in?(@user.store_ids)
        end
      end

      can :manage, MagicBean::PromoCode, ["promo_codes.store_id IN (?)", @user.store_ids] do |resource|
        resource.store_id.in?(@user.store_ids)
      end

      can :manage, MagicBean::SiteConfig, ["site_configs.store_id IN (?)", @user.store_ids] do |resource|
        resource.store_id.in?(@user.store_ids)
      end if @user.permissions.include?("site_configs")
      can :manage, MagicBean::MultiLangConfig, ["site_configs.store_id IN (?)", @user.store_ids] do |resource|
        resource.store_id.in?(@user.store_ids)
      end if @user.permissions.include?("multi_lang_configs")
      can :manage, MagicBean::CustomList, ["custom_lists.store_id IN (?)", @user.store_ids] do |resource|
        resource.store_id.in?(@user.store_ids)
      end if @user.permissions.include?("custom_lists")
      can :manage, MagicBean::CustomPage, ["custom_pages.store_id IN (?)", @user.store_ids] do |resource|
        resource.store_id.in?(@user.store_ids)
      end if @user.permissions.include?("custom_pages")
      can :manage, MagicBean::SelfPickUp, ["self_pick_ups.store_id IN (?)", @user.store_ids] do |resource|
        resource.store_id.in?(@user.store_ids)
      end if @user.permissions.include?("self_pick_ups")

      can :manage, MagicBean::PagePopup, ["page_popups.store_id IN (?)", @user.store_ids] do |resource|
        resource.store_id.in?(@user.store_ids)
      end if @user.permissions.include?("page_popups")

      can :manage, MagicBean::OperationRecord, ["operation_records.store_id IN (?)", @user.store_ids] do |resource|
        resource.store_id.in?(@user.store_ids)
      end if @user.permissions.include?("operation_records")

      can [:read, :create], MagicBean::AdminAssignIntegralRecord, ["admin_assign_integral_records.store_id IN (?)", @user.store_ids] do |resource|
        resource.store_id.in?(@user.store_ids)
      end if @user.permissions.include?("operation_records")

      can :manage, MagicBean::ExternalLink if @user.permissions.include?("external_links")

      can :manage, MagicBean::ExternalMiniProgram if @user.permissions.include?("external_mini_programs")

      can :read, MagicBean::SkuInStockNotice if @user.permissions.include?("sku_in_stock_notices")

      can [:read, :create, :update, :destroy], MagicBean::PushMessage, ["push_messages.store_id IN (?)", @user.store_ids] do |resource|
        resource.store_id.in?(@user.store_ids)
      end if @user.permissions.include?("push_messages")

      can :manage, MagicBean::MarketingMessage, ["marketing_messages.store_id IN (?)", @user.store_ids] do |resource|
        resource.store_id.in?(@user.store_ids)
      end if @user.permissions.include?("marketing_messages")

      can :manage, MagicBean::ExtraOrdersLimit, ["extra_orders_limits.store_id IN (?)", @user.store_ids] do |resource|
        resource.store_id.in?(@user.store_ids)
      end if @user.permissions.include?("extra_orders_limits")

      can :manage, MagicBean::CouponAutoAssignment if @user.permissions.include?("coupon_auto_assignments")

      can :manage, MagicBean::LiveRoom, ["live_rooms.store_id IN (?)", @user.store_ids] do |resource|
        resource.store_id.in?(@user.store_ids)
      end

      if @user.permissions.include?("live_room_viewed_users")
        can :manage, MagicBean::LiveRoomViewedUser
        can :manage, MagicBean::LiveRoomViewedUserStat
      end
      can :manage, MagicBean::LiveRoomOrder if @user.permissions.include?("live_room_orders")
      can :manage, MagicBean::MobileBlacklist if @user.permissions.include?("mobile_blacklists")

      can :manage, MagicBean::SignInActivity if @user.permissions.include?("sign_in_activities")

      can :manage, MagicBean::BannerClick if @user.permissions.include?("banner_clicks")

      can :manage, MagicBean::OverseasStudentApplication if @user.permissions.include?("overseas_student_applications")

      can :manage, MagicBean::Auction::Activity if @user.permissions.include?("auction_activities")
      can :manage, MagicBean::AuctionOrder if @user.permissions.include?("auction_orders")
      can :manage, MagicBean::ItemBanner if @user.permissions.include?("item_banners")

      can :manage, MagicBean::WebBanner, ["web_banners.store_id IN (?)", @user.store_ids] do |resource|
        resource.store_id.in?(@user.store_ids)
      end if @user.permissions.include?("web_banners")
      can :manage, MagicBean::WebCustomList, ["web_custom_lists.store_id IN (?)", @user.store_ids] do |resource|
        resource.store_id.in?(@user.store_ids)
      end if @user.permissions.include?("web_custom_lists")
      can :manage, MagicBean::PaymentSetting, ["payment_settings.store_id IN (?)", @user.store_ids] do |resource|
        resource.store_id.in?(@user.store_ids)
      end

      can [:read, :update], MagicBean::ThirdPartyOrder, ["third_party_orders.store_id IN (?)", @user.store_ids] do |resource|
        resource.store_id.in?(@user.store_ids)
      end if @user.permissions.include?("third_party_orders")

      can [:read], MagicBean::WarehouseOrder, ["warehouse_orders.store_id IN (?)", @user.store_ids] do |resource|
        resource.store_id.in?(@user.store_ids)
      end if @user.permissions.include?("warehouse_orders")

      can :manage, MagicBean::HotSellConfig, ["hot_sell_configs.store_id IN (?)", @user.store_ids] do |resource|
        resource.store_id.in?(@user.store_ids)
      end if @user.permissions.include?("hot_sell_configs")

      can :manage, MagicBean::ItemTagType if @user.permissions.include?("item_tag_types")
      can :manage, MagicBean::ItemTagGroup if @user.permissions.include?("item_tag_groups")
      can :manage, MagicBean::ItemTag if @user.permissions.include?("item_tags")

      can :manage, MagicBean::TopLeftItemTag, ["top_left_item_tags.store_id IN (?)", @user.store_ids] do |resource|
        resource.store_id.in?(@user.store_ids)
      end if @user.permissions.include?("top_left_item_tags")

      can :manage, MagicBean::SkuSalesMailerSetting, ["sku_sales_mailer_settings.store_id IN (?)", @user.store_ids] do |resource|
        resource.store_id.in?(@user.store_ids)
      end if @user.permissions.include?("sku_sales_mailer_settings")
    end

    def user_abilities
      base_user_abilities
      can [:read, :assign_coupon], MagicBean::CouponTemplate
      can :read, MagicBean::Coupon, @user.coupons do |resource|
        resource.user_id == @user.id
      end
      can :read, MagicBean::PromoCode, order_id: nil
      can [:read, :create, :close, :confirm_goods, :request_wechat_payment, :request_wechat_payment, :request_stripe_payment, :request_commweb_payment, :apply_refund, :reorder_check, :reorder, :destroy], MagicBean::Order, @user.orders do |resource|
        resource.user_id == @user.id
      end
      can [:read, :create, :update, :destroy], MagicBean::Invoice, user_id: @user.id
      can :create, MagicBean::Comment do |resource|
        if resource.commentable_type.eql?("MagicBean::OrderItem")
          resource.commentable&.order&.user_id == @user.id
        else
          false
        end
      end
      can [:read, :create, :update_logistic_info, :close], MagicBean::AfterSale, @user.after_sales do |resource|
        resource.user_id == @user.id && resource.order_id.in?(@user.order_ids)
      end
      can [:read, :assign_coupon_template], MagicBean::CouponPackage
      can :read, MagicBean::Groupon
      can :read, MagicBean::CustomPage
      can :read, MagicBean::CustomList
      can :read, MagicBean::PagePopup, MagicBean::PagePopup.active do |resource|
        resource.active?
      end
      can [:read, :create], MagicBean::UserSuggestion, @user.user_suggestions do |resource|
        resource.user_id == @user.id
      end
      can [:read, :create], MagicBean::UserRecommendedProduct, @user.user_recommended_products do |resource|
        resource.user_id == @user.id
      end
      can :read, MagicBean::IntegralRecord
      can [:read, :update, :destroy, :create], MagicBean::Address, @user.addresses do |resource|
        resource.user_id == @user.id
      end
      can :read, MagicBean::SelfPickUp
      can :read, MagicBean::DeliveryArea
      can :create, SubscribeRecord
      can :read, MagicBean::Comment, user: @user

      can :create, SkuInStockNotice, user_id: @user.id

      can :read, PushMessage, PushMessage.left_joins(:users_push_messages).pushed.where("push_at >= ?", @user.created_at).where("push_messages.store_id IS NULL OR users_push_messages.user_id = #{@user.id}") do |resource|
        resource.pushed? && resource.push_at >= @user.created_at && (resource.store_id.nil? || resource.users_push_messages.exists?(user_id: @user.id))
      end

      can [:read, :update, :destroy, :create], MagicBean::AppTextMessage, user_id: @user.id

      can :create, OrderInvoice, order_id: @user.order_ids

      can :manage, MagicBean::LiveRoom, host_id: @user.id

      can :manage, MagicBean::LiveRoomLotteryWinningUser, user_id: @user.id

      can [:read], MagicBean::Auction::ActivityParticipation, user_id: @user.id
    end

    def base_user_abilities
      can :read, MagicBean::Groupon
      can :read, MagicBean::CustomPage
      can :read, MagicBean::CustomList
      can :read, MagicBean::Item
      can :read, MagicBean::FormItem
      can :read, MagicBean::CouponTemplate
      can :read, MagicBean::CouponPackage
      can :read, MagicBean::PagePopup, MagicBean::PagePopup.active do |resource|
        resource.active?
      end
      can :read, MagicBean::SelfPickUp
      can :read, MagicBean::DeliveryArea
      can :read, MagicBean::Store
      can :read, MagicBean::Brand
      can :read, MagicBean::AgeVerification
      can :read, MagicBean::GiftCardCoupon
      can :read, MagicBean::GiftActivity, MagicBean::GiftActivity.active do |resource|
        current_time = Time.current
        resource.enabled? && resource.start_at <= current_time && resource.end_at >= current_time
      end
      can :read, MagicBean::HotSearch
      can :read, MagicBean::LiveRoom
      can :read, MagicBean::SignInActivity
      can :read, MagicBean::Auction::Activity
      can :read, MagicBean::HomepagePagingSetting
      can :read, MagicBean::MinePageActivitySetting
      can :read, MagicBean::HotSellConfig
    end
  end
end
