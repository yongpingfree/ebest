# frozen_string_literal: true

module OrderConcern
  module GiftActivity
    extend ActiveSupport::Concern

    included do
      # constants

      # concerns

      # attr related macros
      attr_accessor :gift_sku_ids, :gift_price_gradient

      # association macros
      belongs_to :gift_activity, optional: true

      # validation macros

      # callbacks
      before_validation :set_gifts_properties

      # other macros

      # scopes

      # class methods

      # instance methods
    end

    def preview_gift_activity
      active_activity = MagicBean::GiftActivity.active.where(store_id: store_id).first

      return if active_activity.blank?

      self.gift_activity = active_activity
    end

    def set_gifts_properties
      return if gift_activity_id.blank? || gift_sku_ids.blank?

      gift_activity = MagicBean::GiftActivity.active.where(store_id: store_id).find_by(id: gift_activity_id)

      if gift_activity.blank?
        errors.add(:base, I18n.t("error.gift_activity.promotion_ended"))
        return
      end

      self.gifts_properties = gift_activity.gifts_properties_for(self, gift_sku_ids, gift_coupon_template_id, gift_price_gradient)
    end
  end
end
