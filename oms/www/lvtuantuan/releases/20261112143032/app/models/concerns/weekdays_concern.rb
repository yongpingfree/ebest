# frozen_string_literal: true

module WeekdaysConcern
  extend ActiveSupport::Concern

  WEEKDAYS = ["0", "1", "2", "3", "4", "5", "6"]

  included do
    validates :weekdays, presence: true
    validate :check_weekdays
  end

  private
  def check_weekdays
    errors.add(:weekdays, "包含无效数据")  if (weekdays - WEEKDAYS).any?
  end
end
