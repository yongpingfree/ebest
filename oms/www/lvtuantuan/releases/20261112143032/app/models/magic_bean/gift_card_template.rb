# frozen_string_literal: true

module MagicBean
  class GiftCardTemplate < ApplicationRecord
    include PriceConvertConcern

    enum purpose: {
      campaign: 1, # 活动用
      sale: 2, # 销售用
      after_sale: 3 # 售后
    }

    has_many :gift_card_coupons, dependent: :destroy

    convert_price_to_yuan :denominations_in_cent

    validates :quantity, :denominations_in_cent, presence: true, numericality: { greater_than: 0 }
    validates_presence_of :expired_at, :purchaser
    validate :check_expired_at

    after_create :generate_gift_card_coupons, :enqueue_expired_job

    def self.store_ids_contains(store_ids = [])
      if store_ids == "all"
        all
      elsif store_ids.present?
        where("store_ids @> ARRAY[?]::integer[]", store_ids)
      else
        where(store_ids: [])
      end
    end

    private
    def check_expired_at
      errors.add(:expired_at, "不能小于当前时间") if expired_at <= Time.current
    end

    def generate_gift_card_coupons
      MagicBean::GiftCardCoupon.transaction do
        (1..quantity).each do
          gift_card_coupons.create!
        end
      end
    end

    def enqueue_expired_job
      ExpiredGiftCardCouponJob.set(wait_until: expired_at).perform_later(id)
    end
  end
end
