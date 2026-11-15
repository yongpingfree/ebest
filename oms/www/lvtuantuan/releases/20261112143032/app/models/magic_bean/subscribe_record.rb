# frozen_string_literal: true
module MagicBean
  class SubscribeRecord < ApplicationRecord
    # concerns

    # scope

    # constants
    TARGETABLE_TYPES = %w(MagicBean::Order MagicBean::AfterSale)

    # attr related macros

    # association macros
    belongs_to :targetable, polymorphic: true
    belongs_to :user

    # validation macros

    # callbacks

    # other macros

    # instance methods

    # class methods

    # private methods
    def is_useless?
      case targetable_type
      when "MagicBean::AfterSale"
        %w(finished closed).include?(targetable.status)
      when "MagicBean::Order"
        %w(trade_finished trade_closed).include?(targetable.status)
      end
    end
  end
end
