# frozen_string_literal: true

module MagicBean
  class SignInActivity < ApplicationRecord

    # scope
    scope :enabled, -> { where(enabled: true) }
    scope :active, -> { enabled.where(arel_table[:end_at].gt(Time.current).and(arel_table[:start_at].lt(Time.current))) }

    # attr related macros
    translates :title
    globalize_accessors attributes: [:title]

    enum extra_reward_type: {
      consecutive: 1, # 连续
      accumulative: 2 # 累计
    }

    # association macros
    has_many :sign_in_histories, dependent: :destroy
    has_many :sign_in_reward_histories, dependent: :destroy

    # validation macros
    validates :title_zh_cn, :detail_image, :start_at, :end_at, :extra_reward_type, presence: true
    validates :reward_integral_each_time, :sign_in_times, :extra_reward_integral, presence: true, numericality: { greater_than: 0 }
    validate :check_start_at_and_end_at_valid, :check_only_one_active_activity_in_a_period

    # callbacks
    before_save :set_i18n_attributes

    def extra_reward!(user)
      # 需要找到最近一次额外奖励时间
      newest_extra_reward = sign_in_reward_histories.extra.where(user_id: user.id).order(created_at: :desc).first
      newest_extra_reward_date = newest_extra_reward&.created_at&.to_date
      # 如果今天已经领过额外奖励则返回false
      return false if newest_extra_reward_date == Date.current

      next_min_date = nil
      next_min_date = newest_extra_reward_date + 1.day if newest_extra_reward_date

      if consecutive_sign_in_times_fulfilled?(user, next_min_date) || accumulative_sign_in_times_fulfilled?(user, next_min_date)
        sign_in_reward_histories.extra.create(user_id: user.id, integral: extra_reward_integral)
        return true
      end

      false
    end

    def mini_program_path

    end

    def app_path
      { type: "signInActivity" }.to_json
    end

    private

    def check_start_at_and_end_at_valid
      errors.add(:base, I18n.t("errors.messages.start_at_can_not_later_than_end_at")) if start_at && end_at && start_at > end_at
    end

    def set_i18n_attributes
      return unless title_changed?
      return if manually_updated_translations?

      if title_zh_cn.present? && title_changed?
        self.title_zh_tw = Ropencc.conv("s2tw.json", title_zh_cn)
        self.title_en = EasyTranslate.translate(title_zh_cn, from: :"zh-CN", to: :en)
      end
    end

    def manually_updated_translations?
      changed_keys = changes.keys
      changed_keys.include?("title_zh_tw") || changed_keys.include?("title_en")
    end

    def check_only_one_active_activity_in_a_period
      if enabled? && exists_other_activity?
        errors.add(:base, "同个时间段内只能有一个启用的签到活动")
      end
    end

    def exists_other_activity?
      MagicBean::SignInActivity.enabled.where.not(id: id)
        .where(":start_at < end_at AND :end_at > start_at", { start_at: start_at, end_at: end_at }).exists?
    end

    def consecutive_sign_in_times_fulfilled?(user, next_min_date)
      min_date = (sign_in_times - 1).days.ago.to_date
      min_date = next_min_date if next_min_date && next_min_date > min_date

      consecutive? && sign_in_histories.where(user_id: user.id, sign_in_date: min_date..Date.current).count >= sign_in_times
    end

    def accumulative_sign_in_times_fulfilled?(user, next_min_date)
      if next_min_date
        accumulative? && sign_in_histories.where(user_id: user.id).where("sign_in_date > ?", next_min_date).count >= sign_in_times
      else
        accumulative? && sign_in_histories.where(user_id: user.id).count >= sign_in_times
      end
    end
  end
end
