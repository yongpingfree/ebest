# frozen_string_literal: true

module MagicBean
  class SignInRewardHistory < ApplicationRecord
    belongs_to :user
    belongs_to :sign_in_history, optional: true
    belongs_to :sign_in_activity

    validates :integral, presence: true, numericality: { greater_than: 0 }

    after_create :reward_integral

    enum reward_type: {
      each_time: 1, # 单次签到奖励
      extra: 2 # 额外签到奖励
    }

    def reward_integral
      user.member.create_integral_record("sign_in_#{reward_type}".to_sym, self, "app", integral)
    end
  end
end
