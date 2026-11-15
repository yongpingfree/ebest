# frozen_string_literal: true

module BeansAdmin
  class API::V1 < API
    prefix "api"
    version "v1"

    mount BeansAdmin::API::V1::Sessions
    mount BeansAdmin::API::V1::Passwords
    mount BeansAdmin::API::V1::Utils

    before do
      authenticate!
      params[:store_id] = current_store_id unless options.dig(:route_options, :skip_store_id)
      params[:store_id_eq] = current_store_id unless options.dig(:route_options, :skip_store_id_filter)
    end

    mount BeansAdmin::API::V1::Users
    mount BeansAdmin::API::V1::RoleTemplates
    mount BeansAdmin::API::V1::AdminUsers
    mount BeansAdmin::API::V1::Categories
    mount BeansAdmin::API::V1::WebCategories
    mount BeansAdmin::API::V1::SiteConfigs
    mount BeansAdmin::API::V1::FreightTemplates
    mount BeansAdmin::API::V1::Provinces
    mount BeansAdmin::API::V1::Items
    mount BeansAdmin::API::V1::FormItems
    mount BeansAdmin::API::V1::FormItemApplications
    mount BeansAdmin::API::V1::QiniuMeta
    mount BeansAdmin::API::V1::SkuProperties
    mount BeansAdmin::API::V1::SkuValues
    mount BeansAdmin::API::V1::Orders
    mount BeansAdmin::API::V1::VirtualOrders
    mount BeansAdmin::API::V1::ThirdPartyOrders
    mount BeansAdmin::API::V1::WarehouseOrders
    mount BeansAdmin::API::V1::AfterSales
    mount BeansAdmin::API::V1::SkuReturns
    mount BeansAdmin::API::V1::Dashboard
    mount BeansAdmin::API::V1::Analysis
    mount BeansAdmin::API::V1::QaAndGuarantees
    mount BeansAdmin::API::V1::CouponTemplates
    mount BeansAdmin::API::V1::GiftCardTemplates
    mount BeansAdmin::API::V1::GiftCardCoupons
    mount BeansAdmin::API::V1::Brands
    mount BeansAdmin::API::V1::Mine
    mount BeansAdmin::API::V1::Coupons
    mount BeansAdmin::API::V1::GrouponActivities
    mount BeansAdmin::API::V1::Comments
    mount BeansAdmin::API::V1::CouponPackages
    mount BeansAdmin::API::V1::CustomPages
    mount BeansAdmin::API::V1::CustomLists
    mount BeansAdmin::API::V1::Pages
    mount BeansAdmin::API::V1::ReportPages
    mount BeansAdmin::API::V1::Members
    mount BeansAdmin::API::V1::PagePopups
    mount BeansAdmin::API::V1::UserSuggestions
    mount BeansAdmin::API::V1::UserRecommendedProducts
    mount BeansAdmin::API::V1::Logistics
    mount BeansAdmin::API::V1::GiftActivities
    mount BeansAdmin::API::V1::Aliyuns
    mount BeansAdmin::API::V1::SelfPickUps
    mount BeansAdmin::API::V1::DeliveryAreas
    mount BeansAdmin::API::V1::AuSuburbs
    mount BeansAdmin::API::V1::DeliveryTimes
    mount BeansAdmin::API::V1::SameDayDeliveryTimes
    mount BeansAdmin::API::V1::OperationRecords
    mount BeansAdmin::API::V1::AdminAssignIntegralRecords
    mount BeansAdmin::API::V1::StockKeepingUnits
    mount BeansAdmin::API::V1::OrderPaidAnalyses
    mount BeansAdmin::API::V1::AppDownloadChannels
    mount BeansAdmin::API::V1::Stores
    mount BeansAdmin::API::V1::Products
    mount BeansAdmin::API::V1::AppDownloadChannels
    mount BeansAdmin::API::V1::CouponAutoAssignments
    mount BeansAdmin::API::V1::PushMessages
    mount BeansAdmin::API::V1::AppTextMessages
    mount BeansAdmin::API::V1::MarketingMessages
    mount BeansAdmin::API::V1::EventPages
    mount BeansAdmin::API::V1::EventFormRecords
    mount BeansAdmin::API::V1::ExternalLinks
    mount BeansAdmin::API::V1::ExternalMiniPrograms
    mount BeansAdmin::API::V1::VerificationCodes
    mount BeansAdmin::API::V1::TimeLimitedPromotions
    mount BeansAdmin::API::V1::PromoCodeTemplates
    mount BeansAdmin::API::V1::PromoCodes
    mount BeansAdmin::API::V1::ExtraOrdersLimits
    mount BeansAdmin::API::V1::HotSearches
    mount BeansAdmin::API::V1::BannerClicks
    mount BeansAdmin::API::V1::LiveRooms
    mount BeansAdmin::API::V1::LiveRoomLotteries
    mount BeansAdmin::API::V1::LiveRoomViewedUsers
    mount BeansAdmin::API::V1::LiveRoomViewedUserStats
    mount BeansAdmin::API::V1::LiveRoomOrders
    mount BeansAdmin::API::V1::MobileBlacklists
    mount BeansAdmin::API::V1::PreferentialPools
    mount BeansAdmin::API::V1::SignInActivities
    mount BeansAdmin::API::V1::MultiLangConfigs
    mount BeansAdmin::API::V1::AgeVerifications
    mount BeansAdmin::API::V1::TimeZones
    mount BeansAdmin::API::V1::OverseasStudentApplications
    mount BeansAdmin::API::V1::Auction::Activities
    mount BeansAdmin::API::V1::AuctionOrders
    mount BeansAdmin::API::V1::ItemBanners
    mount BeansAdmin::API::V1::WebBanners
    mount BeansAdmin::API::V1::WebCustomLists
    mount BeansAdmin::API::V1::PaymentSettings
    mount BeansAdmin::API::V1::HomepagePagingSettings
    mount BeansAdmin::API::V1::MinePageActivitySettings
    mount BeansAdmin::API::V1::AwsOss
    mount BeansAdmin::API::V1::HotSellConfigs
    mount BeansAdmin::API::V1::ItemTagTypes
    mount BeansAdmin::API::V1::ItemTagGroups
    mount BeansAdmin::API::V1::ItemTags
    mount BeansAdmin::API::V1::TopLeftItemTags
    mount BeansAdmin::API::V1::SkuSalesMailerSettings

    add_swagger_documentation info: {
      title: "管理后台 API"
    }
  end
end
