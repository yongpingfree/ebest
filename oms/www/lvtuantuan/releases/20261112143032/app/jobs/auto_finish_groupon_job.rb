# frozen_string_literal: true

class AutoFinishGrouponJob < ApplicationJob
  queue_as :groupon

  def perform(groupon_id)
    groupon = MagicBean::Groupon.find_by(id: groupon_id)
    # 假拼团才能自动成团, 真拼团到期cancel
    if groupon && (groupon.waiting? || groupon.filled?)
      groupon.groupon_activity.is_real ? groupon.expire! : groupon.auto_finish!
    end
  end
end
