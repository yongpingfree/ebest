# frozen_string_literal: true
module MagicBean
  class SkuGroupon < ApplicationRecord
    include PriceConvertConcern

    # scope
    scope :enabled, -> { where(enabled: true) }

    # constants

    # attr related macros
    convert_price_to_yuan :price_in_cent

    # association macros
    belongs_to :item, optional: true
    belongs_to :groupon_activity
    belongs_to :stock_keeping_unit

    # validation macros
    validates_uniqueness_of :stock_keeping_unit, scope: :groupon_activity
    validates_numericality_of :price_in_cent, greater_than: 0, if: :enabled

    # callbacks
    before_validation :set_item_id, on: :create

    delegate :no, :price_in_yuan, to: :stock_keeping_unit, prefix: true

    # other macros

    private

    def set_item_id
      self.item_id = groupon_activity.item_id
    end
  end
end
