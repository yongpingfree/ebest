# frozen_string_literal: true
module MagicBean
  class QaAndGuarantee < ApplicationRecord
    translates :image, :title
    globalize_accessors attributes: [:image, :title]

    has_many :items, dependent: :restrict_with_error

    validates :title, presence: true
    validates :image, presence: true
    validates :web_image, presence: true
  end
end
