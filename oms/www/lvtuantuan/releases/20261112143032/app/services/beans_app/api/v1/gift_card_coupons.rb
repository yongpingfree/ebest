# frozen_string_literal: true

module BeansApp
  class API::V1::GiftCardCoupons < ::API
    namespace :gift_card_coupons, desc: "礼品券 API" do
      desc "查找礼品券", {
        success: API::Entities::GiftCardCoupon
      }
      params do
        requires :code, type: String, desc: "状礼品券码"
        requires :pin_code, type: String, desc: "礼品券PIN码"
        optional :gift_card_store_id, type: Integer, desc: "store_id"
      end
      get "detail" do
        gift_card_coupon = MagicBean::GiftCardCoupon.find_by(code: params[:code], pin_code: params[:pin_code])

        if gift_card_coupon
          response_error(I18n.t("grape.gift_card_coupons.store_not_available")) if gift_card_coupon.store_ids.present? && params[:gift_card_store_id].present? && !params[:gift_card_store_id].in?(gift_card_coupon.store_ids)
          response_error(I18n.t("grape.gift_card_coupons.already_used")) if gift_card_coupon.used?
          response_error(I18n.t("grape.gift_card_coupons.expired")) if gift_card_coupon.expired?
          present gift_card_coupon,  with: API::Entities::GiftCardCoupon
        else
          response_error(I18n.t("grape.gift_card_coupons.invalid_info"))
        end
      end
    end
  end
end
