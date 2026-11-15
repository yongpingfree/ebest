# frozen_string_literal: true
module MagicBean
  class CouponPackagesUser < ApplicationRecord
    belongs_to :user
    belongs_to :coupon_package
  end
end
