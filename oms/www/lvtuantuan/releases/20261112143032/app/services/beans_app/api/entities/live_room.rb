# frozen_string_literal: true

module BeansApp::API::Entities
  class LiveRoom < ::CommonEntities::Model
    expose :title, documentation: { desc: "直播间名称" }
    expose :host_nickname, documentation: { desc: "主播昵称" }
    expose :host_id
    expose :start_at
    expose :state
    expose :viewed_count
    expose :liked_count
    expose :app_live_pull_url
    expose :app_live_pull_url_raw, documentation: { desc: "原始分辨率拉流地址" }
    expose :app_live_pull_url_ld, documentation: { desc: "流畅分辨率拉流地址" }
    expose :app_live_pull_url_sd, documentation: { desc: "标清分辨率拉流地址" }
    expose :app_live_pull_url_hd, documentation: { desc: "高清分辨率拉流地址" }
    expose :app_live_push_url, if: -> (live_room, _) { current_user&.is_host && current_user.id == live_room.host_id }
    expose :bg_color, documentation: { desc: "直播间背景色" }
    expose :bg_img, documentation: { desc: "直播间背景图" }
    expose :share_icon, documentation: { desc: "分享图标" }
    expose :subscribed, documentation: { desc: "是否已订阅" }
    expose :announcement, documentation: { desc: "直播间公告" }
    expose :custom_page_icon, documentation: { desc: "自定义页面图标 URL" }
    expose :custom_page_id, documentation: { desc: "自定义页面ID" }
    expose :custom_page_en_name, documentation: { desc: "自定义页面英文名称" }
    expose :subscription_count, documentation: { type: Integer, desc: "订阅开播通知用户数" }
    expose :orientation, documentation: { desc: "播放方向：portrait: 竖向，landscape: 横向" }
    expose :coupon_package, using: BeansApp::API::Entities::CouponPackage
    expose :highlighted_sku, using: BeansApp::API::Entities::SimpleStockKeepingUnit
    expose :current_lottery, using: BeansApp::API::Entities::LiveRoomLottery
    expose :live_room_token

    def subscribed
      current_user.present? ? object.live_room_subscriptions.exists?(user_id: current_user.id) : false
    end

    def live_room_token
      if current_user
        object.generate_live_room_token(current_user)
      end
    end
  end
end
