# frozen_string_literal: true

class LiveChannel < ApplicationCable::Channel
  DETAILS_PAGE_SCENE = "live_room_details_page".freeze

  before_subscribe :set_live_room

  def subscribed
    return reject if @live_room.nil?

    if @live_room.live_state?
      @live_room.increase_viewed_count
      @live_room.add_viewed_user(current_user_id)
      @live_room.cal_peak_concurrent_users_count
      @live_room.log_user_start_viewed_at(current_user_id)

      if current_user.present? && DETAILS_PAGE_SCENE == scene
        ActionCable.server.broadcast(@live_room.channel_name,
                                     {
                                       action: "enter",
                                       text: "#{current_user.fuzzy_name}加入了直播间"
                                     })
      end
    end

    stream_from @live_room.channel_name
  end

  def like(data)
    count = data["count"].to_i
    @live_room.increase_liked_count(count)
    @live_room.add_liked_user(current_user_id)

    ActionCable.server.broadcast(@live_room.channel_name,
                                 {
                                   action: "like",
                                   count: @live_room.live_liked_count
                                 })
  end

  # data需包含nickname,content
  def comment(data)
    if current_user_id.to_i.to_s != current_user_id.to_s || !MagicBean::User.exists?(id: current_user_id)
      transmit({ action: "unauthorized", message: "Unauthorized." })
      return
    end

    @live_room.reload

    if @live_room.redis_comment_disabled_user_ids.include?(current_user_id)
      # 黑名单用户直接返回自己评论的内容
      return transmit(data)
    else
      @live_room.increase_commented_count
      @live_room.add_commented_user(current_user_id)
      comment_with_id = data.slice("nickname", "content").merge("id" => SecureRandom.hex(4))
      @live_room.redis_latest_comments << comment_with_id

      if @live_room.has_active_lottery? && @live_room.current_lottery_comment_to_draw?
        @live_room.add_user_to_current_lottery(current_user_id)
      end

      # 直播期间主播会叫用户刷评论，先不保存到数据库
      # @live_room.enqueue_save_comments_job(data, current_user_id, connection.current_device_id, connection.current_user_ip)

      ActionCable.server.broadcast(@live_room.channel_name, data)
    end
  end

  def unsubscribed
    if @live_room&.live_state?
      @live_room.calculate_user_viewed_duration(current_user_id)
      @live_room.remove_viewd_user(current_user_id)
    end
  end

  private

  def set_live_room
    @live_room ||= MagicBean::LiveRoom.find_by(id: params[:live_room_id])
  end
end
