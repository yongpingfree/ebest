# frozen_string_literal: true
module MagicBean
  class MobileBlacklist < ApplicationRecord
    # constants

    # concerns
    include MobileBlacklistImportConcern

    # attr related macros

    # association macros
    belongs_to :user, optional: true

    # validation macros
    validates :mobile, uniqueness: true, format: { with: /\A\d{11}\z/ }

    # callbacks
    before_validation :set_user
    before_save :set_time_range
    after_commit :update_user_is_block, :add_user_id_to_live_room, if: ->(record) { record.user_id.present? }

    # other macros

    # scopes
    scope :active, -> { where("enabled = ? AND started_at <= ? AND ended_at >= ?", true, Time.current, Time.current) }

    # class methods

    # instance methods
    def self.activated?(mobile, kind)
      blacklist = self.active.find_by(mobile: mobile)

      blacklist.present? ? blacklist[kind] : false
    end

    def activated?
      enabled && started_at <= Time.current && ended_at >= Time.current
    end

    private

    def set_user
      self.user_id = MagicBean::Member.find_by(mobile: mobile)&.user_id
    end

    # 自动设置时间，简化生效黑名单的时间范围查询
    def set_time_range
      self.started_at ||= Time.current.beginning_of_day
      self.ended_at ||= (Time.current + 100.years).end_of_day
    end

    def update_user_is_block
      if activated? && order_disabled?
        user.update_column(:is_blocked, true)
      end

      if !order_disabled?
        user.update_column(:is_blocked, false)
      end
    end

    def add_user_id_to_live_room
      # 更新进行中的直播黑名单
      MagicBean::LiveRoom.live_state.find_each do |live_room|
        next unless activated?

        if live_comment_disabled?
          live_room.redis_comment_disabled_user_ids << user_id
        else
          live_room.redis_comment_disabled_user_ids.delete user_id
        end

        if live_lottery_disabled?
          live_room.redis_lottery_disabled_user_ids << user_id
        else
          live_room.redis_lottery_disabled_user_ids.delete user_id
        end
      end
    end
  end
end
