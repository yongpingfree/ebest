 # frozen_string_literal: true

module PeriodScopeConcern
  extend ActiveSupport::Concern

  def self.included(klass)
    klass.instance_eval do
      scope :today, -> { where(arel_table[:created_at].gteq(Time.current.beginning_of_day)) }
      scope :yesterday, -> { where(arel_table[:created_at].gteq(Time.current.yesterday.beginning_of_day).and(arel_table[:created_at].lteq(Time.current.yesterday.end_of_day))) }
      scope :recent_day, -> (day) { where(arel_table[:created_at].gteq((Time.current - (day - 1).day).beginning_of_day)) }
    end
  end
end
