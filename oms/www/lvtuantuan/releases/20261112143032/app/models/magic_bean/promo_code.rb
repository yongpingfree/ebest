# frozen_string_literal: true

class MagicBean::PromoCode < ApplicationRecord
  # constants

  # concerns
  include GenerateCodeConcern

  # attr related macros

  # association macros
  belongs_to :promo_code_template
  has_many :orders, dependent: :restrict_with_error
  has_many :paid_orders, -> { paid }, class_name: "MagicBean::Order"

  # validation macros
  validates :code, presence: true, uniqueness: { scope: :promo_code_template_id }
  validates :total_avaliable_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :used_count, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: :total_avaliable_count }, if: -> { total_avaliable_count > 0 }

  # callbacks
  before_validation :generate_code, unless: :code?
  before_validation :set_store_id

  # other macros
  delegate :promo_stock_keeping_units, to: :promo_code_template

  # scopes
  scope :active, -> { where(promo_code_template: MagicBean::PromoCodeTemplate.active).unused }
  scope :used, -> { where("total_avaliable_count > 0 AND total_avaliable_count <= used_count") }
  scope :unused, -> { where("used_count < total_avaliable_count OR total_avaliable_count = 0") }

  # class methods

  # instance methods
  def set_store_id
    self.store_id = promo_code_template.store_id
  end

  # 如果
  def can_use?(user_id)
    # 避免用户用两个手机同时下单，这里的user需要重新获取
    user = MagicBean::User.find user_id

    # 总可用次数为 0 时代表不限制使用总数
    (total_avaliable_count.zero? || remaining_usable_count.positive?) && user_valid?(user) && use_time_valid?(user)
  end

  # 仅限新人可用的情况
  def user_valid?(user)
    !promo_code_template.new_user? || user.new_user
  end

  def use_time_valid?(user)
    # 如果是仅限用一次，需要判断订单是否使用过该code
    if promo_code_template.one_time?
      code_ids = promo_code_template.promo_codes.ids
      return false if user.orders.effective.exists?(promo_code_id: code_ids)
    end

    true
  end

  def remaining_usable_count
    total_avaliable_count - used_count
  end
end
