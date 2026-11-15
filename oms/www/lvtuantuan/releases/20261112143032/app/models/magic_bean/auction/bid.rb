# frozen_string_literal: true

module MagicBean
  class Auction::Bid < ApplicationRecord
    # constants

    # concerns
    include PriceConvertConcern

    # attr related macros
    enum kind: { direct: 0, automatic: 1 }

    convert_price_to_yuan :amount_in_cent

    # association macros
    belongs_to :user
    belongs_to :auction_activity, class_name: "MagicBean::Auction::Activity", counter_cache: true
    belongs_to :member

    # validation macros
    validates :amount_in_cent, presence: true, numericality: {
        greater_than_or_equal_to: -> (bid) { bid.auction_activity.next_bid_amount_in_cent },
        less_than: 10000000000,
        message: I18n.t("errors.must_greater_than_current_bid", scope: MagicBean::Auction::Activity::I18N_SCOPE)
      }, uniqueness: { scope: :auction_activity_id, message: I18n.t("errors.taken", scope: MagicBean::Auction::Activity::I18N_SCOPE) }
    validate :amount_increment_is_multiple_of_bidding_increment
    validate :amount_not_greater_than_purchase_price

    # callbacks
    after_create_commit :update_auction_activity, :update_activity_participation, :notify_new_bid

    # other macros
    delegate :best_automatic_bid, to: :auction_activity, allow_nil: true
    delegate :fuzzy_name, to: :user, prefix: true

    # scopes

    # class methods

    # instance methods

    private

    def update_auction_activity
      auction_activity.update best_bid_id: id, best_bid_amount_in_cent: amount_in_cent
      auction_activity.check_and_enqueue_hammer_job

      if should_generate_next_automatic_bid?
        MagicBean::Auction::Bid.create(
          user_id: best_automatic_bid.user_id,
          member_id: best_automatic_bid.user.member_id,
          auction_activity_id: auction_activity_id,
          amount_in_cent: auction_activity.reload.next_bid_amount_in_cent,
          kind: :automatic
        )
      end
    end

    def should_generate_next_automatic_bid?
      direct? && best_automatic_bid.present? && best_automatic_bid.amount_limit_in_cent > amount_in_cent
    end

    def amount_increment_is_multiple_of_bidding_increment
      diff = amount_in_cent - auction_activity.next_bid_amount_in_cent
      if (diff % auction_activity.bidding_increments_in_cent) != 0
        self.errors.add(:amount_in_cent, I18n.t("errors.must_be_multiple_of_bidding_increment", scope: MagicBean::Auction::Activity::I18N_SCOPE))
      end
    end

    def amount_not_greater_than_purchase_price
      return if auction_activity.directly_purchase_price_in_cent.nil?

      if amount_in_cent > auction_activity.directly_purchase_price_in_cent
        self.errors.add(:amount_in_cent, I18n.t("errors.not_greater_than_purchase_price", scope: MagicBean::Auction::Activity::I18N_SCOPE))
      end
    end

    def update_activity_participation
      participation =  user.auction_activity_participations.find_or_create_by(
        auction_activity_id: auction_activity.id, store_id: auction_activity.store_id
      )

      participation.update_attribute :amount_in_cent, amount_in_cent
    end

    def notify_new_bid
      auction_activity.notify_participants_new_bid(user_id, amount_in_cent)
    end
  end
end
