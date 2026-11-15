# frozen_string_literal: true

class RewardBirthdayJob < ApplicationJob
  queue_as :default

  def perform(member_id)
    member =  MagicBean::Member.find_by(id: member_id)

    if member && member.birthday?
      # 有的生日修改了，触发两次job，需要检查执行任务时间是否在生日当天
      birthday_month_day = member.birthday.strftime("%m-%d")
      # 这里要考虑生日是闰年2月29日，且今年不是闰年
      if birthday_month_day == "02-29" && !Date.leap?(Date.current.year)
        return if Date.current.strftime("%m-%d") != "02-28"
      else
        return if Date.current.strftime("%m-%d") != birthday_month_day
      end      

      # 检查用户今年是否已经领过生日券
      user = member.user
      template = user.web? ? MagicBean::CouponTemplate.web_birthday(user.selected_store_id) : MagicBean::CouponTemplate.birthday(user.selected_store_id)
      member.send(:reward_birthday) if template && !template.coupons.exists?(user_id: user.id, created_at: Time.current.beginning_of_year..Time.current.end_of_year)

      # 触发第二年发生日礼物定时任务
      # wait: 1.year 不会准确等到一年后再执行，改用wait_until
      RewardBirthdayJob.set(wait_until: 1.year.from_now).perform_later(member_id)
    end
  end
end
