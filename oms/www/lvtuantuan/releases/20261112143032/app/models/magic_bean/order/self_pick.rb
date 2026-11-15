# frozen_string_literal: true

class MagicBean::Order
  # 订单短信相关
  module SelfPick
    extend ActiveSupport::Concern

    private
    # 暂时弃用，目前是使用前端传过来的delivery_date和prefer_time，无需再计算
    def set_self_pick_up_prefer_time
      return if !self_pick? || self_pick_up.nil?
      current_time = Time.current
      delivery_date = current_time.to_date
      delivery_date = current_time < CUTOFF_TIME.in_time_zone ? delivery_date + 1 : delivery_date + 2

      limit = 1
      loop do
        break if delivery_date.wday.to_s.in?(self_pick_up.weekdays)
        delivery_date += 1
        limit += 1
        break if limit > 7
      end

      self.delivery_date = delivery_date
      self.prefer_time = self_pick_up.time_period.first
    end
  end
end
