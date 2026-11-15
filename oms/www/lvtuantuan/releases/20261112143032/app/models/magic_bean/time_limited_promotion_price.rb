# frozen_string_literal: true

module MagicBean
  class TimeLimitedPromotionPrice < ApplicationRecord
    # constants

    # concerns
    include PriceConvertConcern

    # attr related macros
    convert_price_to_yuan :price_in_cent

    # association macros
    belongs_to :time_limited_promotion
    belongs_to :stock_keeping_unit

    # validation macros
    validates :price_in_cent, numericality: { greater_than: 0 }
    validates :quantity, numericality: { greater_than_or_equal_to: 0 }
    validates :reserved_quantity, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
    validates :buy_quota, numericality: { greater_than_or_equal_to: 0 }
    validates :buy_quota_days, numericality: { greater_than_or_equal_to: 0 }
    validate :sku_time_range_not_conflict

    # callbacks
    delegate :human_title, :no, :barcode, to: :stock_keeping_unit, prefix: true
    after_save :update_item_price
    after_commit :enqueue_reset_item_price_job, if: -> { saved_change_to_start_at? || saved_change_to_end_at? }
    after_commit :update_item_in_time_limited_promotion_state

    # other macros

    # scopes
    scope :active, -> { where(enabled: true).where("time_limited_promotion_prices.quantity_updated_at <= ? AND time_limited_promotion_prices.end_at > ?", Time.current, Time.current) }
    scope :sort_by_position, -> { order(position: :asc, id: :asc) }

    # class methods

    # instance methods
    def check_price_less_than_supplier_cost_multiple
      stock_keeping_unit.price_less_than_supplier_cost_multiple?(price_in_cent)
    end

    def update_item_in_time_limited_promotion_state
      stock_keeping_unit.item.update_in_time_limited_promotion_info
    end

    private

    def sku_time_range_not_conflict
      stock_keeping_unit.valid_time_limited_promotions.where.not(id: time_limited_promotion.id).each do |promo|
        unless (promo.end_at < time_limited_promotion.start_at || promo.start_at > time_limited_promotion.end_at)
          self.errors.add(:base, "#{stock_keeping_unit.human_title}与【#{promo.title}】的时间（#{promo.start_at} ~ #{promo.end_at}）有重叠")
        end
      end
    end

    def update_item_price
      stock_keeping_unit.send :calculate_and_update_item_price
    end

    def enqueue_reset_item_price_job
      PromotionPriceResetItemPriceJob.set(wait_until: start_at).perform_later(id) if start_at > Time.current
      PromotionPriceResetItemPriceJob.set(wait_until: end_at).perform_later(id) if end_at > Time.current
    end
  end
end
