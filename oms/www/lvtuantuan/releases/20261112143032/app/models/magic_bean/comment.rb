# frozen_string_literal: true

class MagicBean::Comment < ApplicationRecord
  include WechatSecurityCheckConcern
  # scope
  scope :top_level, -> { where(parent_id: nil) }

  # constants
  COMMENTABLE_TYPES = %w[MagicBean::OrderItem]
  MSG_SEC_CHECK_ATTRIBUTES = ["content"]
  # IMG_SEC_CHECK_ATTRIBUTES = ["images"]

  # attr related macros
  acts_as_taggable

  acts_as_paranoid
  enum status: {
    pending: 1,
    show: 2,
    banned: 3
  }
  ransacker :status, formatter: proc { |v| statuses[v] }

  delegate :content, :id, to: :reply, prefix: true, allow_nil: true
  delegate :title, to: :item, prefix: true

  # association macros
  belongs_to :user, optional: true
  belongs_to :commentable, polymorphic: true, optional: true
  belongs_to :item, counter_cache: true
  belongs_to :stock_keeping_unit, optional: true
  has_one :reply, class_name: "MagicBean::Comment", foreign_key: "parent_id", dependent: :destroy
  belongs_to :parent, class_name: "MagicBean::Comment", foreign_key: "parent_id", optional: :true

  # validation macros
  validates :content, :user_nickname, presence: true
  validate :check_commentable, on: :create
  # 星数1-5分
  validates :stars, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }

  # callbacks
  before_validation :set_item, if: :should_set_item?
  before_validation :set_user_info, on: :create, if: :user_id
  before_validation :set_reply_default_value, on: :create, if: :parent_id

  # other macros

  def cover
    images.first
  end

  private

  def check_commentable
    return true if commentable.nil?

    if commentable && MagicBean::Comment.exists?(commentable: commentable, user: user)
      errors.add(:base, I18n.t("error.comment.already_commented"))
    else
      case commentable
      when MagicBean::OrderItem
        errors.add(:base, I18n.t("error.comment.please_confirm_goods")) if commentable.order.wait_buyer_confirm_goods?
        errors.add(:base, I18n.t("error.comment.no_permission_to_comment")) unless user.order_items.exists?(id: commentable.id)
      end
    end
  end

  def set_item
    case commentable
    when MagicBean::OrderItem
      self.item = commentable.item
      self.stock_keeping_unit = commentable.stock_keeping_unit
      self.properties_text = stock_keeping_unit.properties_text
    end

    if stock_keeping_unit
      self.properties_text = stock_keeping_unit.properties_text
    end
  end

  def set_user_info
    self.user_avatar = user.avatar
    self.user_nickname = user.nickname
  end

  def should_set_item?
    commentable_id_changed? || stock_keeping_unit_id_changed?
  end

  def set_reply_default_value
    self.user_nickname = MagicBean::SiteConfig.default_config&.customer_service_name
    self.status = "show"
  end
end
