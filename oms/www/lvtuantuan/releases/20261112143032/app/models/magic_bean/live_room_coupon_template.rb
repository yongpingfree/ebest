# frozen_string_literal: true

module MagicBean
  class LiveRoomCouponTemplate < ApplicationRecord
    belongs_to :live_room
    belongs_to :coupon_template

    delegate :title, to: :coupon_template, prefix: true
  end
end
