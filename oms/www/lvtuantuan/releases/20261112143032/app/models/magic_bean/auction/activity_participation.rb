# frozen_string_literal: true

module MagicBean
  class Auction::ActivityParticipation < ApplicationRecord
    # constants

    # concerns
    include PriceConvertConcern
    include AASM

    # attr related macros
    enum state: {
      bidding: 2, # 拍卖中
      paying: 3, # 中标且等待付款
      sold: 4, # 成交
      pass: 5, # 出价没达到底价
      pay_timeout: 6, # 弃标，中标后超过 24 小时未付款
      direct_buy: 7, # 直接购买
      failed: 8 # 未得标
    }, _suffix: true
    convert_price_to_yuan :amount_in_cent

    # association macros
    belongs_to :user
    belongs_to :store
    belongs_to :auction_activity, class_name: "MagicBean::Auction::Activity"
    belongs_to :auction_order, optional: true

    # validation macros
    validates :auction_activity_id, uniqueness: { scope: :user_id }
    validates :amount_in_cent, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 999999999 }

    # callbacks

    # other macros
    delegate :name, to: :store, prefix: true

    ransacker :state, formatter: proc { |val| states[val] }

    aasm :state, column: :state, enum: true do
      state :bidding, initial: true
      state :paying
      state :sold
      state :pass
      state :pay_timeout
      state :direct_buy

      event :win do
        transitions from: :bidding, to: :paying
      end

      event :direct_buy do
        transitions from: :bidding, to: :direct_buy
      end

      event :sale do
        transitions from: :paying, to: :sold
      end

      event :timeout do
        transitions from: :paying, to: :pay_timeout
      end
    end
    # scopes

    # class methods

    # instance methods
  end
end
