# frozen_string_literal: true

class ClearLastYearIntegralEveryMonthJob < ApplicationJob
  queue_as :default

  # 每个月1号凌晨清除上一年未使用积分，如2023/10/01 清 2022/10/01 以前产生且未使用的金币
  def perform(*)
    end_time = Time.current.beginning_of_month - 1.year

    # 现在的系统是不会有冻结积分存在，所以这里直接把冻结积分清零
    MagicBean::Member.update_all(app_blocked_integral: 0)

    # id为4的会员不清金币
    MagicBean::Member.includes(:user).where("app_available_integral > 0").where.not(id: 4).each do |member|
      # 用户在end_time之后共使用的积分总数
      cost_integral = member.integral_records.app.where(kind: [:spent, :spent_return]).where("created_at >= ?", end_time).sum(:integral)
      # 用户在end_time之前的可用积分数
      last_year_available_integral = member.integral_records.app.where("created_at < ?", end_time).order(id: :desc).first&.available_integral.to_i

      # 检查用户在end_time之后清除过多少积分
      # 每次计算可清除积分，需要减除已经清除过的积分，才不会多扣积分
      history_expired_integral = member.integral_records.app.integral_expired.where("created_at > ?", end_time).sum(:integral)

      # 不可过期积分 = 已经清除过的积分 + 本次已使用的积分
      can_not_expired_integral = history_expired_integral.abs + cost_integral.abs
      
      # 用户上一年剩余积分 大于 今年的使用积分，则积分要做扣除
      if can_not_expired_integral < last_year_available_integral
        member.with_lock do
          expired_integral = last_year_available_integral - can_not_expired_integral
          expired_integral = [member.app_available_integral, expired_integral].min
          available_integral = member.app_available_integral - expired_integral

          member.update(app_available_integral: available_integral)
          member.create_integral_record(:integral_expired, nil, "app", expired_integral)
        end
      end
    end
  end
end
