# frozen_string_literal: true

class CheckMemberRewardBirthdayJob < ApplicationJob
  queue_as :default

  def perform
    # 现在每天都会有用户收不到生日券，检查不到原因，每天下午2点再主动检查一遍
    total_member_ids = MagicBean::Member.where.not(birthday: nil).ids
    scheduled_jobs = Sidekiq::ScheduledSet.new
    not_reward_member_ids = []
    
    scheduled_jobs.each do |job|
      if job.value.include?("RewardBirthdayJob")
        value = JSON.parse job.value
        not_reward_member_ids << value["args"].first["arguments"].first
      end
    end

    MagicBean::Member.where(id: total_member_ids - not_reward_member_ids).each do |member|
      member.send :enqueue_reward_birthday_job
    end
  end
end
