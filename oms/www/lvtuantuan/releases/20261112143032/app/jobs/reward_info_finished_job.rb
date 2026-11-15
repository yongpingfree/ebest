# frozen_string_literal: true

class RewardInfoFinishedJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user =  MagicBean::User.find_by(id: user_id)

    user.send :reward_info_finished if user
  end
end
