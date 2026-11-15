# frozen_string_literal: true

class MagicBean::CutoffTime < ApplicationRecord
  WEEKDAYS = %w(0 1 2 3 4 5 6)
  belongs_to :item
  validate :check_weekdays, :check_time_at
  validates :deliver_after_n_days, presence: true
  validates :deliver_after_n_days, numericality: { greater_than_or_equal_to: 0 }

  private
  def check_weekdays
    if (weekdays - WEEKDAYS).any?
      errors.add(:weekdays, "包含无效数据")
    elsif weekdays.blank?
      errors.add(:weekdays, "不能为空")
    end
  end

  def check_time_at
    errors.add(:time_at, "不能为空") if time_at.blank?
  end
end
