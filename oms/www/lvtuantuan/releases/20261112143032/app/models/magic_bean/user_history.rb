# frozen_string_literal: true

module MagicBean
  class UserHistory < ApplicationRecord
    # constants
    REDIS_LIST_KEY = "user_history_params"

    # concerns

    # attr related macros
    # 来源
    enum channel: {
      mini_program: 1,
      app: 2,
      web: 3
    }

    # association macros
    belongs_to :user
    belongs_to :operatable, polymorphic: true
  end
end
