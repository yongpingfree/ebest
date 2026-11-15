# frozen_string_literal: true
module BeansAdmin::API::Entities
  class LiveRoom < SimpleLiveRoom
    expose :average_user_viewed_time_for_human
    expose :agora_m3u8_vod_url
    expose :agora_mp4_vod_urls
    expose :live_room_skus, using: LiveRoomSku
    expose :coupon_package, using: CouponPackage
    expose :custom_page, using: CustomPage
  end
end
