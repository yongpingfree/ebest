# frozen_string_literal: true
module MagicBean
  class UserSuggestion < ApplicationRecord
    include AASM

    # scope

    # constants

    # attr related macros
    enum status: {
      pending: 1,
      adopted: 2,
      ignored: 3
    }

    enum channel: {
      mini_program: 1,
      app: 2,
      web: 3
    }

    ransacker :status, formatter: proc { |v| statuses[v] }

    aasm column: :status, enum: true do
      state :pending, initial: true
      state :adopted
      state :ignored

      event :adopt do
        transitions from: [:pending, :ignored], to: :adopted, after: :suggestion_reward
      end

      event :ignore do
        transitions from: :pending, to: :ignored
      end
    end

    # association macros
    belongs_to :user
    has_many :integral_records, as: :targetable

    delegate :member, :nickname, to: :user
    delegate :mobile, to: :member, prefix: true, allow_nil: true

    # validation macros
    validates_presence_of :content
    validates :content, presence: true, length: { maximum: 500 }

    # callbacks
    before_update :set_replied_at, if: :reply_changed?

    # other macros

    private

    def suggestion_reward
      member.send(:suggest_reward, self, channel) if member
    end

    def set_replied_at
      self.replied_at = Time.current
    end
  end
end
