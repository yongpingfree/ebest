# frozen_string_literal: true

class TimedExpireCouponsJob < ApplicationJob
  queue_as :default

  def perform
    MagicBean::Coupon.pending.where("expired_at < ?", Time.current).update_all(status: :expired)
  end
end
