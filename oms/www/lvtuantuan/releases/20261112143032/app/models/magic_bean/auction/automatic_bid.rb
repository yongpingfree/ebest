# frozen_string_literal: true

module MagicBean
  class Auction::AutomaticBid < ApplicationRecord
    # constants

    # concerns
    include PriceConvertConcern

    # attr related macros
    convert_price_to_yuan :amount_limit_in_cent

    # association macros
    belongs_to :user
    belongs_to :auction_activity, class_name: "MagicBean::Auction::Activity", counter_cache: true

    # validation macros
    validates :amount_limit_in_cent, presence: true,
      numericality: {
        greater_than_or_equal_to: -> (bid) { bid.auction_activity.next_bid_amount_in_cent },
        less_than: 10000000000,
        message: I18n.t("errors.must_greater_than_current_bid", scope: MagicBean::Auction::Activity::I18N_SCOPE)
      }, uniqueness: { scope: :auction_activity_id, message: I18n.t("errors.taken", scope: MagicBean::Auction::Activity::I18N_SCOPE) }
    validate :amount_limit_is_multiple_of_bidding_increment
    validate :amount_limit_not_greater_than_purchase_price

    # callbacks

    # other macros

    # scopes

    # class methods

    # instance methods

    private

    def amount_limit_is_multiple_of_bidding_increment
      diff = amount_limit_in_cent - auction_activity.next_bid_amount_in_cent
      if (diff % auction_activity.bidding_increments_in_cent) != 0
        self.errors.add(:amount_limit_in_cent, I18n.t("activerecord.attributes.magic_bean/auction/activity.errors.must_be_multiple_of_bidding_increment"))
      end
    end

    def amount_limit_not_greater_than_purchase_price
      return if auction_activity.directly_purchase_price_in_cent.nil?

      if amount_limit_in_cent > auction_activity.directly_purchase_price_in_cent
        self.errors.add(:amount_limit_in_cent, I18n.t("errors.not_greater_than_purchase_price", scope: MagicBean::Auction::Activity::I18N_SCOPE))
      end
    end
  end
end
