# frozen_string_literal: true

module BeansApp
  class API::V1 < API
    prefix "api"
    version "v1"

    before do
      authenticate! if require_authentication?

      if current_user
        if current_store_id&.positive? && current_user.selected_store_id != current_store_id
          current_user.selected_store_id = current_store_id
        end

        if current_user.locale != I18n.locale.to_s
          current_user.locale = I18n.locale.to_s
        end

        if current_app_version.present? && current_user.app_version != current_app_version
          current_user.app_version = current_app_version
        end

        current_user.save if current_user.changed?
      end

      MagicBean::Current.postal_code = current_postal_code
      MagicBean::Current.suburb = current_suburb
      MagicBean::Current.store_id = current_store_id
      Time.zone = current_store_time_zone
    end

    mount BeansApp::API::V1::Users
    # mount BeansApp::API::V1::ShoplineUsers
    mount BeansApp::API::V1::Categories
    mount BeansApp::API::V1::WebCategories
    mount BeansApp::API::V1::Items
    mount BeansApp::API::V1::FormItems
    mount BeansApp::API::V1::ShoppingCartItems
    mount BeansApp::API::V1::SameDayDeliveryCartItems
    mount BeansApp::API::V1::Orders
    mount BeansApp::API::V1::Wechats
    mount BeansApp::API::V1::Addresses
    mount BeansApp::API::V1::Mine
    mount BeansApp::API::V1::AfterSales
    mount BeansApp::API::V1::Logistics
    mount BeansApp::API::V1::QiniuMetas
    mount BeansApp::API::V1::Comments
    mount BeansApp::API::V1::Coupons
    mount BeansApp::API::V1::CouponTemplates
    mount BeansApp::API::V1::GiftCardCoupons
    mount BeansApp::API::V1::Captchas
    mount BeansApp::API::V1::ActionStores
    mount BeansApp::API::V1::Invoices
    mount BeansApp::API::V1::CouponPackages
    mount BeansApp::API::V1::Groupons
    mount BeansApp::API::V1::Members
    mount BeansApp::API::V1::CustomPages
    mount BeansApp::API::V1::CustomLists
    mount BeansApp::API::V1::PagePopups
    mount BeansApp::API::V1::UserSuggestions
    mount BeansApp::API::V1::UserRecommendedProducts
    mount BeansApp::API::V1::SiteConfigs
    mount BeansApp::API::V1::SubscribeRecords
    mount BeansApp::API::V1::Aliyuns
    mount BeansApp::API::V1::AwsOss
    mount BeansApp::API::V1::GooglePlace
    mount BeansApp::API::V1::SelfPickUps
    mount BeansApp::API::V1::DeliveryAreas
    mount BeansApp::API::V1::AuSuburbs
    mount BeansApp::API::V1::TencentAddresses
    mount BeansApp::API::V1::Stores
    mount BeansApp::API::V1::Brands
    mount BeansApp::API::V1::Sessions
    mount BeansApp::API::V1::CommwebPayments
    mount BeansApp::API::V1::SkuInStockNotices
    mount BeansApp::API::V1::PushMessages
    mount BeansApp::API::V1::PromoCodes
    mount BeansApp::API::V1::OrderInvoices
    mount BeansApp::API::V1::BannerClicks
    mount BeansApp::API::V1::AppTextMessages
    mount BeansApp::API::V1::HotSearches
    mount BeansApp::API::V1::LiveRooms
    mount BeansApp::API::V1::LiveRoomLotteries
    mount BeansApp::API::V1::LiveRoomLotteryWinningUsers
    mount BeansApp::API::V1::SignInActivities
    mount BeansApp::API::V1::MultiLangConfigs
    mount BeansApp::API::V1::AgeVerifications
    mount BeansApp::API::V1::OverseasStudentApplications
    mount BeansApp::API::V1::Auction::Activities
    mount BeansApp::API::V1::Auction::ActivityParticipations
    mount BeansApp::API::V1::ItemBanners
    mount BeansApp::API::V1::WebBanners
    mount BeansApp::API::V1::WebCustomLists
    mount BeansApp::API::V1::Pages
    mount BeansApp::API::V1::HomepagePagingSettings
    mount BeansApp::API::V1::MinePageActivitySettings
    mount BeansApp::API::V1::TimeLimitedPromotions
    mount BeansApp::API::V1::HotSellConfigs

    add_swagger_documentation info: {
      title: "APP API"
    }
  end
end
