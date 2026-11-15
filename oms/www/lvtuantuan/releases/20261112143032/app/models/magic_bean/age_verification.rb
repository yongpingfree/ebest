# frozen_string_literal: true

module MagicBean
  class AgeVerification < ApplicationRecord
    belongs_to :parent_category, class_name: "MagicBean::Category", optional: true
    belongs_to :parent_web_category, class_name: "MagicBean::WebCategory", optional: true

    validates :image, presence: true
    validate :at_least_one_category

    translates :title, :content
    globalize_accessors attributes: [:title, :content]

    delegate :name, to: :parent_category, prefix: true, allow_nil: true
    delegate :name, to: :parent_web_category, prefix: true, allow_nil: true

    private

    def at_least_one_category
      errors.add(:base, "至少需要关联一个分类") unless parent_category || parent_web_category
    end
  end
end
