# frozen_string_literal: true

class CleanCouponPackageCollectedUserJob < ApplicationJob
  queue_as :default

  def perform(id)
    cp = MagicBean::CouponPackage.find(id)
    cp.collected_user_ids.clear if Time.current >= cp.end_at
  end
end
