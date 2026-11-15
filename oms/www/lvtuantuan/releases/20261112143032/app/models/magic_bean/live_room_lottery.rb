# frozen_string_literal: true

module MagicBean
  class LiveRoomLottery < ApplicationRecord
    # constants

    # concerns
    include AASM
    include Redis::Objects

    # attr related macros
    enum state: { pending: 0, started: 1, finished: 2 }, _suffix: true
    enum draw_method: { comment: 0, click: 1 }

    # association macros
    belongs_to :live_room

    has_many :live_room_lottery_winning_users, dependent: :destroy
    has_many :winning_users, through: :live_room_lottery_winning_users, source: :user

    # validation macros
    validates :name, presence: true
    validates :luck_limit, presence: true, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 100 }
    validates :duration_in_minutes, presence: true, numericality: { only_integer: true, greater_than: 0 }
    validates :award_cover, presence: true

    # callbacks

    # other macros
    set :redis_drawed_user_ids

    aasm :state, column: :state, enum: true do
      state :pending, initial: true
      state :started, :finished

      event :start do
        transitions from: :pending, to: :started do
          guard do
            !live_room.reload.has_active_lottery?
          end
        end

        after do
          touch(:started_at)
          live_room.set_new_lottery(self)
          enqueue_finish_lottery_job
          live_room.broadcast_lottery_start
        end
      end

      event :finish do
        transitions from: [:pending, :started], to: :finished
        after do
          select_winning_users
          live_room.end_current_lottery
        end
      end
    end

    # scopes

    # class methods

    # instance methods
    def finished_at
      return if pending_state?

      started_at + duration_in_minutes.minutes
    end

    def enqueue_finish_lottery_job
      FinishLiveRoomLotteryJob.set(wait: duration_in_minutes.minutes).perform_later(id)
    end

    def select_winning_users
      users_pool = live_room.current_lottery_users_set.members.map(&:to_i) - ineligible_user_ids_for_current_lottery - lottery_blacklist_user_ids
      return [] if users_pool.blank?

      winning_user_ids = users_pool.sample(luck_limit)
      user_ids_with_lottery_id = winning_user_ids.map { |user_id| { user_id: user_id, live_room_lottery_id: id, live_room_id: live_room_id } }
      MagicBean::LiveRoomLotteryWinningUser.create(user_ids_with_lottery_id)
    end

    def winning_users_of_other_lotteries
      live_room.live_room_lottery_winning_users.where.not(live_room_lottery_id: id)
    end

    def ineligible_user_ids_for_current_lottery
      if live_room.lottery_win_limits.positive?
        winning_users_of_other_lotteries.group(:user_id).count.select do |user_id, winning_count|
          winning_count >= live_room.lottery_win_limits
        end.keys
      else
        # 中奖上限为 0 时不限制中奖次数
        []
      end
    end

    def lottery_blacklist_user_ids
      live_room.redis_lottery_disabled_user_ids.members.map(&:to_i)
    end
  end
end
