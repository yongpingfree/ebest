# frozen_string_literal: true

class FinishLiveRoomLotteryJob < ApplicationJob
  # TODO: 调整 sidekiq queue 权重、减少队列数量，以减少对 redis 调度压力
  # ref: https://github.com/mperham/sidekiq/wiki/Advanced-Options
  queue_as :default

  def perform(id)
    lottery = MagicBean::LiveRoomLottery.find_by(id: id)
    if lottery.present? && lottery.may_finish?
      lottery.finish!
    end
  end
end
