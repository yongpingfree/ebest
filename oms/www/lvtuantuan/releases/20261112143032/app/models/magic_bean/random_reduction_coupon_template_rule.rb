# frozen_string_literal: true

module MagicBean
  class RandomReductionCouponTemplateRule < ApplicationRecord
    # constants

    # concerns
    include PriceConvertConcern

    # attr related macros
    convert_price_to_yuan :min_amount_in_cent, :max_amount_in_cent

    # association macros
    belongs_to :coupon_template, inverse_of: :random_reduction_coupon_template_rules

    # validation macros
    validates :min_amount_in_cent, presence: true, numericality: { greater_than: 0, less_than: :max_amount_in_cent }
    validates :max_amount_in_cent, presence: true, numericality: { greater_than: 0 }
    validates :max_quantity, numericality: { greater_than: 0 }
    validates :used_quantity, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: :max_quantity }

    # callbacks

    # other macros

    # scopes
    scope :avaliable, -> { where("used_quantity < max_quantity") }

    # class methods

    # instance methods

    def increment_used_quantity!
      increment!(:used_quantity)
    end
  end
end
