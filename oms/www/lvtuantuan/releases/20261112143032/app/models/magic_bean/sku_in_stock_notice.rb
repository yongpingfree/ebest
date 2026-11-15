# frozen_string_literal: true

module MagicBean
  class SkuInStockNotice < ApplicationRecord
    # constants

    # concerns
    include AASM
    include AASMExtendConcern

    # attr related macros
    enum state: { pending: 0, successed: 1 }

    # association macros
    belongs_to :user
    belongs_to :stock_keeping_unit

    # validation macros

    # callbacks
    after_create :increment_stock_keeping_unit_pending_in_stock_notices_count

    # other macros
    aasm :state, column: :state, enum: true, requires_lock: true do
      state :pending, initial: true
      state :successed

      event :notice, after_commit: [:create_sku_in_stock_message] do
        transitions from: :pending, to: :successed, success: :decrement_stock_keeping_unit_pending_in_stock_notices_count
      end
    end

    # scopes

    # class methods

    # instance methods
    def generate
      return unless valid?

      errors.add(:base, I18n.t("error.sku_in_stock_notice.become_member")) and return unless user.member

      errors.add(:base, I18n.t("error.sku_in_stock_notice.already_subscribed")) and return if self.class.pending.exists?(user_id: user_id, stock_keeping_unit_id: stock_keeping_unit_id)

      errors.add(:base, I18n.t("error.sku_in_stock_notice.can_not_subscribe")) and return if stock_keeping_unit.quantity > 0

      save
    end

    protected
    def increment_stock_keeping_unit_pending_in_stock_notices_count
      stock_keeping_unit.increment!(:pending_in_stock_notices_count)
    end

    def decrement_stock_keeping_unit_pending_in_stock_notices_count
      stock_keeping_unit.decrement!(:pending_in_stock_notices_count)
    end

    def create_sku_in_stock_message
      I18n.with_locale(user.locale) do
        text = I18n.t("activerecord.attributes.magic_bean/sku_in_stock_notice.notification_text", sku_title: stock_keeping_unit.human_title)
        MagicBean::AppTextMessage.create(
          title: text,
          content: text,
          user_id: user_id,
          kind: :sku_in_stock,
          target_type: "MagicBean::Item",
          target_id: stock_keeping_unit.item_id
        )
      end
    end
  end
end
