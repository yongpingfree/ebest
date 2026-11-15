# frozen_string_literal: true
module MagicBean
  class UsersPushMessage < ApplicationRecord
    # constants

    # concerns

    # attr related macros

    # association macros
    belongs_to :push_message
    belongs_to :user

    # validation macros

    # callbacks

    # other macros

    # scopes

    # class methods

    # instance methods
  end
end
