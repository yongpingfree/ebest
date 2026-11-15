# frozen_string_literal: true
require "dynamic_key"

module MagicBean
  class LiveRoom < ApplicationRecord
    # constants
    LIVE_ENTRY_POINT = "live"
    LIVE_PUSH_DOMAIN = "ebest-push-agora.yy-ewe.com"
    LIVE_PULL_DOMAIN = "ebest-play-agora.yy-ewe.com"
    VOD_DOMAIN = "ebest-vod-agora.yy-ewe.com"
    LIVE_SETTINGS = Rails.application.credentials.dig(:agora)
    LIVE_PUSH_AUTH_KEY = LIVE_SETTINGS[:live_push_auth_key]
    LIVE_CALLBACK_SECRET = LIVE_SETTINGS[:live_callback_secret]
    LIVE_DEFAULT_DURATION = 24.hours # 暂定一场直播最长 24 小时
    LIVE_STATISTICS_BROADCAST_INTERNAL = 10.seconds
    LIVE_VIEWED_USER_STAT_INTERNAL = 1.minute
    # 直播转码模板地址：https://console.tencentcloud.com/live/config/transcode
    DEFINITION_SUFFIXS = %w[ld sd hd raw] # 分别为：流畅(low definition)、标清(stardand definition)、高清(high definition)、原始(raw)
    LATEST_COMMENT_COUNT = 50

    # concerns
    include Redis::Objects
    include AASM

    # attr related macros
    enum app_pull_protocol: { flv: 0, rtmp: 1 }, _prefix: true # 拉流优先使用 flv 格式
    enum app_push_protocol: { rtmp: 1 }, _prefix: true # 推流优先使用 RTMP 格式
    enum state: { pending: 0, live: 1, finished: 2 }, _suffix: true
    enum orientation: { portrait: 0, landscape: 1 }

    alias_attribute :name, :title

    # association macros
    belongs_to :host, class_name: "MagicBean::User", foreign_key: "host_id"
    belongs_to :admin_user
    belongs_to :store
    belongs_to :coupon_package, optional: true
    belongs_to :highlighted_sku, class_name: "MagicBean::StockKeepingUnit", optional: true
    belongs_to :custom_page, optional: true
    belongs_to :current_lottery, class_name: "MagicBean::LiveRoomLottery", foreign_key: "current_lottery_id", optional: true
    has_many :live_room_lotteries, dependent: :destroy
    has_many :live_room_lottery_winning_users, dependent: :destroy

    has_many :live_comments, dependent: :destroy
    # 直播sku需要正序返回
    has_many :live_room_skus, -> { order(created_at: :asc) }, dependent: :destroy, inverse_of: :live_room
    accepts_nested_attributes_for :live_room_skus, allow_destroy: true
    has_many :live_room_subscriptions, dependent: :destroy, inverse_of: :live_room
    has_many :live_room_viewed_users, dependent: :destroy
    has_many :live_room_orders, dependent: :destroy
    has_many :orders, through: :live_room_orders
    has_many :live_room_viewed_user_stats, dependent: :destroy

    # validation macros
    validates :title, :start_at, :host_nickname, presence: true
    validates :viewed_count_offset, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validates :viewed_count_multiplier, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
    validates :liked_count_offset, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validates :liked_count_multiplier, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
    validates :subscription_noti_title, presence: true
    validates :subscription_noti_body, presence: true
    validates :subscription_count_offset, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validates :lottery_win_limits, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

    # callbacks
    after_commit :enqueue_finish_live_job, if: :pending_state?

    # other macros
    counter :redis_viewed_count
    counter :redis_peak_concurrent_users_count
    counter :redis_liked_count
    counter :redis_commented_count
    counter :redis_total_viewed_time_in_second
    set :redis_viewed_user_ids
    set :redis_liked_user_ids
    set :redis_commented_user_ids
    set :redis_concurrent_user_ids
    set :redis_comment_disabled_user_ids
    set :redis_lottery_disabled_user_ids
    hash_key :redis_viewed_start_times
    value :current_lottery_draw_method
    list :redis_latest_comments, marshal: true

    aasm :state, column: :state, enum: true do
      state :pending, initial: true
      state :live, :finished

      event :start do
        transitions from: :pending, to: :live
        after do
          touch(:live_at)
          enqueue_live_start_broadcast_job
          enqueue_broadcast_live_statistics_job
          enqueue_live_start_notification_job
          enqueue_live_viewed_user_stat_job
          load_blacklist_user_ids
        end
      end

      event :finish do
        transitions from: [:pending, :live], to: :finished
        after do
          touch(:finished_at)
          calculate_online_users_viewed_time
          count_real_time_viewed_user
          flush_redis_data_to_db
          clear_redis_data
          enqueue_live_finish_broadcast_job
          clear_live_top_cart_items
          generate_live_orders
        end
      end
    end

    delegate :en_name, to: :custom_page, prefix: true, allow_nil: true

    # scopes
    scope :active, -> { where("start_at <= ?", Time.current) }

    # class methods

    # instance methods

    # doc: https://docs.agora.io/cn/fusion-cdn-streaming/streaming-url-fls?platform=RESTful#拼接推流-url
    def rtmp_live_push_url
      "rtmps://#{LIVE_PUSH_DOMAIN}/#{LIVE_ENTRY_POINT}/#{stream_name}?#{auth_params}"
    end

    def rtmp_live_pull_url
      "rtmps://#{LIVE_PULL_DOMAIN}/#{LIVE_ENTRY_POINT}/#{stream_name}"
    end

    DEFINITION_SUFFIXS.each do |definition_suffix|
      define_method "rtmp_live_pull_url_#{definition_suffix}" do
        tmp_stream_name = send "stream_name_#{definition_suffix}"
        "rtmps://#{LIVE_PULL_DOMAIN}/#{LIVE_ENTRY_POINT}/#{tmp_stream_name}"
      end
    end

    def flv_live_pull_url
      "https://#{LIVE_PULL_DOMAIN}/#{LIVE_ENTRY_POINT}/#{stream_name}.flv"
    end

    DEFINITION_SUFFIXS.each do |definition_suffix|
      define_method "flv_live_pull_url_#{definition_suffix}" do
        tmp_stream_name = send "stream_name_#{definition_suffix}"
        "https://#{LIVE_PULL_DOMAIN}/#{LIVE_ENTRY_POINT}/#{tmp_stream_name}.flv"
      end
    end

    def obs_live_push_url
      "rtmps://#{LIVE_PUSH_DOMAIN}/#{LIVE_ENTRY_POINT}/"
    end

    def obs_live_push_secret
      "#{stream_name}?#{auth_params}"
    end

    def app_live_push_url
      send "#{app_push_protocol}_live_push_url"
    end

    def app_live_pull_url
      send "#{app_pull_protocol}_live_pull_url_hd"
    end

    DEFINITION_SUFFIXS.each do |definition_suffix|
      define_method "app_live_pull_url_#{definition_suffix}" do
        send "#{app_pull_protocol}_live_pull_url_#{definition_suffix}"
      end
    end

    def stream_name
      # stream_name 重复会导致后创建的推流覆盖之前创建的
      # 所以生产环境推流 steam name 需要确保唯一
      @stream_name ||= (Rails.env.production? ? id : "TEST#{id}")
    end

    def stream_name_raw
      @stream_name_raw ||= "#{stream_name}_hd" # 原画分辨率声音有问题，用高清画质替换
    end

    def stream_name_ld
      @stream_name_ld ||= "#{stream_name}_ld"
    end

    def stream_name_sd
      @stream_name_sd ||= "#{stream_name}_sd2"
    end

    def stream_name_hd
      @stream_name_hd ||= "#{stream_name}_hd"
    end

    # doc: https://docs.agora.io/cn/fusion-cdn-streaming/streaming-url-fls?platform=RESTfu
    def auth_params
      "sign=#{sign}&ts=#{expired_at_timestamp}"
    end

    def expired_at
      @expired_at ||= (start_at + LIVE_DEFAULT_DURATION)
    end

    def expired_at_timestamp
      @expired_at_timestamp ||= expired_at.in_time_zone.to_i
    end

    # 签名（sign）为防盗链密钥、推流/播流 URL 的路径、失效时间戳 ts 这三部分拼接后的字符串计算得到的 MD5 值。
    # 例如，假设 URL 为 http://domain/live/stream.flv，防盗链密钥为 z2tn3uiny0aasebz，ts 为 1634955000，则
    # sign=MD5(z2tn3uiny0aasebz/live/stream.flv1634955000)=b6ceec4cf7c1bd88e911b72cf39e4715
    def sign
      Digest::MD5.hexdigest("#{LIVE_PUSH_AUTH_KEY}/#{LIVE_ENTRY_POINT}/#{stream_name}#{expired_at_timestamp}")
    end

    def channel_name
      @channel_name ||= "live_room_#{stream_name}"
    end

    def app_statistics_data
      {
        state: state,
        viewed_count: viewed_count
      }
    end

    def increase_viewed_count
      self.redis_viewed_count.increment
    end

    def increase_liked_count(count = 1)
      self.redis_liked_count.increment(count)
    end

    def increase_commented_count
      self.redis_commented_count.increment
    end

    def add_viewed_user(viewed_user_id)
      unless redis_viewed_user_ids.include?(viewed_user_id)
        # 没登录的用户使用设备 ID 或者 IP 来标识，需要判断是否是 integer 类型
        if viewed_user_id.to_i.to_s == viewed_user_id.to_s
          live_room_viewed_users.create(user_id: viewed_user_id)
        end
        self.redis_viewed_user_ids << viewed_user_id
      end

      self.redis_concurrent_user_ids << viewed_user_id
    end

    def add_liked_user(liked_user_id)
      self.redis_liked_user_ids << liked_user_id
    end

    def add_commented_user(commented_user_id)
      self.redis_commented_user_ids << commented_user_id
    end

    def cal_peak_concurrent_users_count
      current_viewing_users_count = redis_concurrent_user_ids.length

      if current_viewing_users_count > redis_peak_concurrent_users_count.value
        self.redis_peak_concurrent_users_count.value = current_viewing_users_count
      end

      redis_peak_concurrent_users_count.value
    end

    def count_real_time_viewed_user
      time = Time.current.strftime("%Y-%m-%d %H:%M")
      record = live_room_viewed_user_stats.find_or_initialize_by(time_str: time)
      record.count += redis_concurrent_user_ids.size
      record.save

      enqueue_live_viewed_user_stat_job if live_state?
    end

    def remove_viewd_user(viewed_user_id)
      self.redis_concurrent_user_ids.delete(viewed_user_id)
    end

    def viewed_count
      if finished_state?
        actual_viewed_count.positive? ? (actual_viewed_count * viewed_count_multiplier + viewed_count_offset) : 0
      else
        live_viewed_count
      end
    end

    def liked_count
      if finished_state?
        actual_liked_count.positive? ? (actual_liked_count * liked_count_multiplier + liked_count_offset) : 0
      else
        live_liked_count
      end
    end

    # 直播中的最新点赞数，用于广播给所有正在观看的用户
    def live_liked_count
      redis_liked_count.value.positive? ? (redis_liked_count.value * liked_count_multiplier + liked_count_offset) : 0
    end

    def live_viewed_count
      redis_viewed_count.value.positive? ? (redis_viewed_count.value * viewed_count_multiplier + viewed_count_offset) : 0
    end

    def subscription_count
      live_room_subscriptions_count * subscription_count_multiplier + subscription_count_offset
    end

    def average_user_viewed_time_for_human
      formated_duration(average_user_viewed_time_in_sec) if finished_state?
    end

    def live_duration_for_human
      if finished_state? && live_at.present?
        formated_duration((finished_at - live_at).to_i)
      else
        formated_duration(0)
      end
    end

    def formated_duration(duration_in_seconds)
      parts = ActiveSupport::Duration.build(duration_in_seconds).parts

      "%02d:%02d:%02d" % [
        parts.fetch(:hours, 0),
        parts.fetch(:minutes, 0),
        parts.fetch(:seconds, 0)
      ]
    end

    def flush_redis_data_to_db
      viewed_user_count = redis_viewed_user_ids.size
      viewed_time_in_sec = viewed_user_count.positive? ? (redis_total_viewed_time_in_second.value / viewed_user_count).to_i : 0

      update(
        actual_viewed_count: redis_viewed_count.value,
        actual_liked_count: redis_liked_count.value,
        actual_viewed_users_count: viewed_user_count,
        actual_liked_users_count: redis_liked_user_ids.size,
        actual_peak_concurrent_users_count: redis_peak_concurrent_users_count.value,
        actual_comments_count: redis_commented_count.value,
        actual_comment_users_count: redis_commented_user_ids.size,
        average_user_viewed_time_in_sec: viewed_time_in_sec
      )
    end

    def log_user_start_viewed_at(user_id)
      # NOTE: 同一个已登录用户在多台设备设备上同时观看直播，统计时间会少一些，
      # 但这种情况估计不会很多，先忽略
      self.redis_viewed_start_times[user_id] ||= Time.current
    end

    def calculate_user_viewed_duration(user_id)
      viewd_start_at = self.redis_viewed_start_times[user_id]
      if viewd_start_at.present?
        viewed_duration_in_seconds = Time.current.to_i - viewd_start_at.to_datetime.to_i
        self.redis_total_viewed_time_in_second.increment viewed_duration_in_seconds
        self.redis_viewed_start_times.delete user_id
      end

      self.redis_total_viewed_time_in_second.value
    end

    def calculate_online_users_viewed_time
      self.redis_viewed_start_times.value.each_pair do |user_id, start_time|
        viewed_duration_in_seconds = finished_at.to_i - start_time.to_datetime.to_i
        self.redis_total_viewed_time_in_second.increment viewed_duration_in_seconds
      end

      self.redis_total_viewed_time_in_second.value
    end

    def enqueue_live_start_broadcast_job
      LiveBroadcastJob.perform_later(id, { action: "start" })
    end

    def enqueue_live_finish_broadcast_job
      LiveBroadcastJob.perform_later(id, { action: "finish" })
    end

    def enqueue_broadcast_live_statistics_job
      BroadcastLiveStatisticsJob.set(wait: LIVE_STATISTICS_BROADCAST_INTERNAL).perform_later(id)
    end

    def enqueue_live_viewed_user_stat_job
      LiveRoomViewedUserStatJob.set(wait: LIVE_VIEWED_USER_STAT_INTERNAL).perform_later(id)
    end

    def enqueue_live_start_notification_job
      SendLiveStartNotificationJob.perform_later(id)
    end

    def enqueue_finish_live_job
      start_at_changes = self.previous_changes[:start_at]

      if start_at_changes && start_at_changes.first.nil? # 首次创建直播间
        FinishLiveRoomJob.set(wait_until: expired_at).perform_later(id)
      elsif start_at_changes.present?  # 更新了直播间的开播时间
        FinishLiveRoomJob.set(wait_until: expired_at).perform_later(id)
      end
    end

    def broadcast_live_room_update
      return unless live_state?

      ActionCable.server.broadcast(channel_name,
       {
         action: "update"
       })
    end

    def clear_redis_data
      redis_viewed_count.clear
      redis_peak_concurrent_users_count.clear
      redis_liked_count.clear
      redis_total_viewed_time_in_second.clear
      redis_viewed_user_ids.clear
      redis_liked_user_ids.clear
      redis_concurrent_user_ids.clear
      redis_viewed_start_times.clear
      redis_comment_disabled_user_ids.clear
      redis_lottery_disabled_user_ids.clear
      redis_latest_comments.clear

      true
    end

    def enqueue_save_comments_job(data, comment_user_id, device_id, user_ip)
      comment_params =
        {
          live_room_id: id,
          user_id: comment_user_id,
          nickname: data["nickname"],
          device_id: device_id,
          user_ip: user_ip,
          content: data["content"],
          commented_at: Time.current.to_i,
        }

      SaveLiveCommentsJob.perform_later(comment_params)
    end

    def mini_program_path
      ""
    end

    def app_path
      { type: "liveRoom", params: { id: id } }.to_json
    end

    def calculate_comments_count
      self.actual_comments_count = live_comments.size
      self.actual_comment_users_count = live_comments.select(:user_id).distinct.count
    end

    def send_live_start_notification_to_subscripters
      user_ids = live_room_subscriptions.pluck(:user_id)
      ::MagicBean::AppNotifier.enqueue_app_push_job(subscription_noti_title, subscription_noti_body, user_ids, app_link: app_path)
    end

    def broadcast_announcement_update
      return unless live_state?

      ActionCable.server.broadcast(channel_name,
       {
         action: "announce",
         content: announcement
       })
    end

    def broadcast_highlighted_sku
      return unless live_state? && highlighted_sku.present?

      data = BeansApp::API::Entities::SimpleStockKeepingUnit.represent(highlighted_sku).to_json

      ActionCable.server.broadcast(channel_name,
       {
         action: "highlight_sku",
         data: data
       })
    end

    def broadcast_reset_highlighted_sku
      return unless live_state?

      ActionCable.server.broadcast(channel_name,
       {
         action: "reset_highlight_sku"
       })
    end

    def has_active_lottery?
      live_state? && current_lottery_id.present?
    end

    def add_user_to_current_lottery(user_id)
      current_lottery_users_set << user_id
    end

    def current_lottery_users_set
      if current_lottery_id.present?
        Redis::Set.new(current_lottery_users_set_redis_key)
      else
        nil
      end
    end

    def current_lottery_users_set_redis_key
      "live_room/#{id}/lottery/#{current_lottery_id}"
    end

    def set_new_lottery(lottery)
      update(current_lottery_id: lottery.id)
      self.current_lottery_draw_method = lottery.draw_method
    end

    def end_current_lottery
      current_lottery_users_set.clear
      current_lottery_draw_method.clear
      update(current_lottery_id: nil)
    end

    def current_lottery_comment_to_draw?
      current_lottery_draw_method.value == "comment"
    end

    def current_lottery_click_to_draw?
      current_lottery_draw_method.value == "click"
    end

    def broadcast_lottery_start
      return unless has_active_lottery?

      data = BeansApp::API::Entities::LiveRoomLottery.represent(current_lottery).to_json

      ActionCable.server.broadcast(channel_name,
       {
         action: "lottery_start",
         data: data
       })
    end

    def import_skus_via_excel(filepath)
      xlsx = Roo::Spreadsheet.open(filepath, extension: :xlsx)
      error_messages = []
      sku_ids = []

      rows = xlsx.sheet(0).parse(headers: true)
      # 跳过两行表头
      rows[2..-1].each.with_index(3) do |row, idx|
        sku_store_id = row["store_id"].to_i
        no = row["no"].try :strip

        break if (!sku_store_id.positive? && no.blank?)

        if sku_store_id.blank? || sku_store_id != store_id
          error_messages << "第#{idx}行：门店ID为空或跟直播间门店不一致"
          next
        end

        if no.blank?
          error_messages << "第#{idx}行：SKU货号不能为空"
          next
        end

        sku = MagicBean::StockKeepingUnit.find_by(store_id: sku_store_id, no: no)
        if sku.blank?
          error_messages << "第#{idx}行：没有找到SKU货号【#{no}】"
          next
        end

        sku_ids << sku.id
      end

      return [false, error_messages.join("；")] if error_messages.any?

      result = ActiveRecord::Base.transaction do
                 sku_ids.uniq.each do |sku_id|
                   self.live_room_skus.find_or_create_by!(stock_keeping_unit_id: sku_id)
                 end
               end

      if result.nil?
        [false, "导入失败，所有数据已回滚"]
      else
        [true, "成功导入 #{result.size} 个商品"]
      end
    end

    def generate_live_room_token(user)
      params = {
        app_id: LIVE_SETTINGS[:live_app_id],
        app_certificate: LIVE_SETTINGS[:app_certificate],
        channel_name: stream_name.to_s,
        uid: user.id,
        # 用户为主播，且为直播间主播时可推流
        role: (user.is_host && user.id == host_id) ? AgoraDynamicKey::RTCTokenBuilder::Role::PUBLISHER : AgoraDynamicKey::RTCTokenBuilder::Role::SUBSCRIBER,
        privilege_expired_ts: (start_at + LIVE_DEFAULT_DURATION).to_i
      }

      token = AgoraDynamicKey::RTCTokenBuilder.build_token_with_uid params

      params[:token] = token
      params.except(:app_certificate, :role, :privilege_expired_ts)
    end

    def generate_live_orders
      return if (live_at.nil? || finished_at.nil?)

      live_sku_ids = live_room_skus.pluck(:stock_keeping_unit_id)
      MagicBean::Order.includes(:order_items).where(created_at: live_at..finished_at).order(created_at: :asc).find_each do |order|
        order_sku_ids = order.order_items.pluck(:stock_keeping_unit_id)
        intersection = live_sku_ids & order_sku_ids
        next if intersection.empty?

        live_room_orders.find_or_create_by(order_id: order.id, user_id: order.user_id)
      end
    end

    def agora_m3u8_vod_url
      "http://#{VOD_DOMAIN}/#{agora_vod_filename}" if agora_vod_filename.present?
    end

    def agora_mp4_vod_urls
      agora_mp4_filenames.map { |filename| "http://#{VOD_DOMAIN}/#{filename}" }
    end

    private

    def load_blacklist_user_ids
      # 只能限制已注册用户在直播间留言或中奖
      MagicBean::MobileBlacklist.active.where.not(user_id: nil).find_each do |record|
        self.redis_comment_disabled_user_ids << record.user_id if record.live_comment_disabled?
        self.redis_lottery_disabled_user_ids << record.user_id if record.live_lottery_disabled?
      end
    end

    # 直播结束后将购物车商品的live_top改为false
    def clear_live_top_cart_items
      room_sku_ids = live_room_skus.map(&:stock_keeping_unit_id)
      return if room_sku_ids.blank?
      MagicBean::ShoppingCartItem.unscoped.where(stock_keeping_unit_id: room_sku_ids).update_all(live_top: false)
    end
  end
end
