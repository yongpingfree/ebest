# frozen_string_literal: true

module MagicBean
  class UserRecommendedProduct < ApplicationRecord
    validates :recommended_products, presence: true, length: { maximum: 500 }

    belongs_to :user
  end
end
