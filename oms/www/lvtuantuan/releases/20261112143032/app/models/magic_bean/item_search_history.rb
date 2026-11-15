# frozen_string_literal: true
module MagicBean
  class ItemSearchHistory < ApplicationRecord
    belongs_to :user

    validates :search_date, presence: true
    validates :word, presence: true, uniqueness: { scope: [:search_date, :user_id, :channel] }

    enum channel: {
      mini_program: 1,
      app: 2,
      web: 3
    }
  end
end
