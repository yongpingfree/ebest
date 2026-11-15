# frozen_string_literal: true

class MagicBean::PromoCodeTemplate < ApplicationRecord
  # constants

  # concerns

  # attr related macros
  enum user_kind: {
    all_user: 1,
    new_user: 2
  }

  enum use_times_kind: {
    no_limit: 1, # 用户不限使用次数
    one_time: 2 # 用户仅限使用一次
  }

  enum purpose: {
    campaign: 1, # 活动用
    after_sale: 2, # 售后用
    other: 3 # 其他
  }

  # association macros
  belongs_to :store

  has_many :promo_codes
  has_many :promo_stock_keeping_units

  accepts_nested_attributes_for :promo_stock_keeping_units, allow_destroy: true

  # validation macros
  validates :title, presence: true
  validates :start_on, presence: true
  validates :end_on, presence: true
  validates :promo_stock_keeping_units, presence: true

  # callbacks

  # other macros

  # scopes
  scope :active, -> { enabled.where("start_on <= :date AND end_on >= :date", { date: Date.current }) }
  scope :enabled, -> { where(enabled: true) }
  scope :item_display, -> { where(display_in_item_detail: true) }

  # class methods

  # instance methods
  def can_edit?
    promo_codes.blank?
  end

  def enqueue_generate_promo_codes_job(qty)
    GeneratePromoCodesJob.perform_later(id, qty)
  end

  def generate_promo_codes(qty = 1, options = {})
    new_promo_codes = []
    transaction do
      promo_code_attributes = {}

      attributes_arrays = Array.new(qty.to_i) { promo_code_attributes.merge(options) }
      new_promo_codes = promo_codes.create(attributes_arrays)
    end
    new_promo_codes
  end
end
