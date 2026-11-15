# frozen_string_literal: true
module BeansAdmin::API::Entities
  class SimpleLiveRoom < ::CommonEntities::Model
    expose :title, documentation: { type: String, desc: "标题" }
    expose :start_at, documentation: { type: DateTime, desc: "开始时间" }
    expose :host_id, documentation: { type: Integer, desc: "直播用户id" }
    expose :host_nickname, documentation: { type: String, desc: "直播用户昵称" }
    expose :app_pull_protocol, documentation: { type: String, desc: "拉流协议" }
    expose :app_push_protocol, documentation: { type: String, desc: "推流协议" }
    expose :app_live_pull_url, documentation: { type: String, desc: "拉流协议" }
    expose :app_live_push_url, documentation: { type: String, desc: "推流协议" }
    expose :obs_live_push_url
    expose :obs_live_push_secret
    expose :viewed_count
    expose :liked_count
    expose :actual_liked_count
    expose :liked_count_offset
    expose :liked_count_multiplier
    expose :actual_viewed_count
    expose :viewed_count_multiplier
    expose :viewed_count_offset
    expose :actual_peak_concurrent_users_count
    expose :actual_viewed_users_count
    expose :actual_liked_users_count
    expose :actual_comments_count
    expose :actual_comment_users_count
    expose :state
    expose :live_duration_for_human
    expose :live_at
    expose :finished_at
    expose :coupon_package_id
    expose :host, using: BeansAdmin::API::Entities::SimpleUser
    expose :bg_color
    expose :bg_img
    expose :live_room_subscriptions_count
    expose :announcement, documentation: { type: String, desc: "直播间公告" }
    expose :highlighted_sku_id
    expose :subscription_noti_title
    expose :subscription_noti_body
    expose :custom_page_icon
    expose :custom_page_id
    expose :share_icon
    expose :subscription_count_offset
    expose :subscription_count_multiplier
    expose :lottery_win_limits, documentation: { type: Integer, desc: "单个用户中奖次数上限" }
    expose :orientation
    expose :highlighted_sku, using: SimpleStockKeepingUnit
  end
end
