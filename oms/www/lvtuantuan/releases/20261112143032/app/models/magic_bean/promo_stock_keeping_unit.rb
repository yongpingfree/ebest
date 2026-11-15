# frozen_string_literal: true

class MagicBean::PromoStockKeepingUnit < ApplicationRecord
  # constants

  # concerns
  include PriceConvertConcern

  # attr related macros
  convert_price_to_yuan :price_in_cent

  # association macros
  belongs_to :promo_code_template
  belongs_to :stock_keeping_unit

  # validation macros
  validates :price_in_cent, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }

  # callbacks

  # other macros

  # scopes

  # class methods

  # instance methods
end
