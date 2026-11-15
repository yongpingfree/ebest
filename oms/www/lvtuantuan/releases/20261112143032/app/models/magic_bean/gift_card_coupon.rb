# frozen_string_literal: true

module MagicBean
  class GiftCardCoupon < ApplicationRecord
    include PriceConvertConcern

    enum status: {
      pending: 1,
      used: 2,
      expired: 3
    }

    belongs_to :gift_card_template
    has_many :orders, dependent: :restrict_with_error
    has_many :effective_orders, -> { effective.order(id: :asc) }, class_name: "MagicBean::Order"

    convert_price_to_yuan :denominations_in_cent, :used_amount_in_cent, :unused_amount_in_cent

    before_validation :initialize_values, on: :create
    validates :denominations_in_cent, presence: true, numericality: { greater_than: 0 }
    validates :used_amount_in_cent, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates_presence_of :code, :pin_code, :expired_at

    ransacker :status, formatter: proc { |v| statuses[v] }

    def unused_amount_in_cent
      denominations_in_cent - used_amount_in_cent
    end

    private

    def initialize_values
      self.denominations_in_cent = gift_card_template.denominations_in_cent
      self.expired_at = gift_card_template.expired_at
      self.store_ids = gift_card_template.store_ids
      self.not_eligible_for_free_gift = gift_card_template.not_eligible_for_free_gift
      loop do
        self.code = "ebest#{SecureRandom.hex(4)}"
        break unless self.class.exists?(code: code)
      end
      loop do
        self.pin_code = "e#{SecureRandom.hex(6)}"
        break unless self.class.exists?(pin_code: pin_code)
      end
    end
  end
end
