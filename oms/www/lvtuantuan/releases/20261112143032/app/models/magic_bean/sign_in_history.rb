# frozen_string_literal: true

module MagicBean
  class SignInHistory < ApplicationRecord
    belongs_to :user
    belongs_to :sign_in_activity
    has_one :each_time_reward_history, -> { each_time }, class_name: "MagicBean::SignInRewardHistory", dependent: :destroy

    validates :sign_in_date, presence: true, uniqueness: { scope: [:sign_in_activity_id, :user_id] }

    def reward_each_time!
      return false if each_time_reward_history.present?
      build_each_time_reward_history(sign_in_activity_id: sign_in_activity_id, integral: sign_in_activity.reward_integral_each_time, user_id: user_id).save
    end
  end
end
